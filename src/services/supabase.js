import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error("⚠️ Falta configuración de Supabase en .env");
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// ==================== AUTH USUARIOS (GOOGLE) ====================

/**
 * Login de usuario con Google (OAuth)
 * Redirige al callback configurado.
 */
export async function userLoginWithGoogle() {
  const redirectTo = `${window.location.origin}/auth/callback`;
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo,
    },
  });

  if (error) throw error;
  return data;
}

/**
 * Logout de usuario (y admin también, Supabase maneja una sola sesión)
 */
export async function userLogout() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

/**
 * Obtener el perfil del usuario autenticado (tabla public.profiles)
 * @returns {Promise<object|null>}
 */
export async function getMyProfile() {
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) throw userError;
  if (!user) return null;

  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .maybeSingle();

  if (error) throw error;
  return data;
}

/**
 * Actualizar el perfil del usuario autenticado
 * @param {{display_name?: string, avatar_url?: string}} updates
 */
export async function updateMyProfile(updates) {
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) throw userError;
  if (!user) throw new Error("No hay sesión activa");

  const patch = {
    ...updates,
  };

  const { data, error } = await supabase
    .from("profiles")
    .update(patch)
    .eq("id", user.id)
    .select("*")
    .single();

  if (error) throw error;
  return data;
}

/**
 * Obtener el VIP público (admin) para mostrar en la vista general.
 * Requiere la función SQL `public.get_vip_profile()`.
 * @returns {Promise<{display_name: string, avatar_url: string|null} | null>}
 */
export async function getVipProfile() {
  const { data, error } = await supabase.rpc("get_vip_profile");
  if (error) throw error;
  // rpc puede devolver array
  if (Array.isArray(data)) return data[0] || null;
  return data || null;
}

// ==================== SERVICIOS PÚBLICOS ====================

/**
 * Obtiene todos los jugadores (lectura pública)
 * @returns {Promise<Array>}
 */
export async function getPlayers() {
  const { data, error } = await supabase
    .from("players")
    .select("*")
    .order("lives", { ascending: true }) // Los con menos vidas primero
    .order("last_name", { ascending: true, nullsFirst: false })
    .order("first_name", { ascending: true, nullsFirst: false })
    .order("nickname", { ascending: true });

  if (error) {
    console.error("Error al obtener jugadores:", error);
    return [];
  }
  return data || [];
}

/**
 * Obtiene un jugador por id (lectura pública)
 * @param {number} playerId
 * @returns {Promise<object|null>}
 */
export async function getPlayerById(playerId) {
  if (!playerId && playerId !== 0) return null;

  const { data, error } = await supabase
    .from("players")
    .select("*")
    .eq("id", playerId)
    .maybeSingle();

  if (error) {
    console.error("Error al obtener jugador:", error);
    return null;
  }

  return data || null;
}

/**
 * Suscripción en tiempo real a cambios en players
 * @param {Function} callback
 * @returns {RealtimeChannel}
 */
export function subscribeToPlayers(callback) {
  return supabase
    .channel("public:players")
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "players" },
      callback
    )
    .subscribe();
}

/**
 * Suscripción en tiempo real a eventos de muerte (life_events)
 * @param {Function} callback
 * @returns {RealtimeChannel}
 */
export function subscribeToLifeEvents(callback) {
  return supabase
    .channel("public:life_events")
    .on(
      "postgres_changes",
      { event: "INSERT", schema: "public", table: "life_events" },
      callback
    )
    .subscribe();
}

// ==================== SERVICIOS ADMIN ====================

/**
 * Login del admin
 * @param {string} email
 * @param {string} password
 */
export async function adminLogin(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) throw error;
  return data;
}

/**
 * Logout del admin
 */
export async function adminLogout() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

/**
 * Obtiene la sesión actual
 */
export async function getSession() {
  const { data, error } = await supabase.auth.getSession();
  if (error) throw error;
  return data.session;
}

/**
 * Sanitizar nombre para archivo (remover caracteres especiales)
 * @param {string} text
 * @returns {string}
 */
function sanitizeFileName(text) {
  // Remover/reemplazar caracteres especiales
  return text
    .normalize("NFD") // Descomponer caracteres acentuados
    .replace(/[\u0300-\u036f]/g, "") // Remover diacríticos
    .replace(/[^a-zA-Z0-9-_]/g, "-") // Remover otros caracteres especiales
    .replace(/-+/g, "-") // Consolidar guiones múltiples
    .toLowerCase(); // Convertir a minúsculas
}

/**
 * Subir imagen del jugador (usuario) a Storage dentro de una carpeta por UID
 * Requiere policy de Storage que permita `bucket_id = 'player-images'` y `name` prefijado con el uid.
 * @param {File} file
 * @param {string} userId
 * @param {string} label
 * @returns {Promise<string>} URL pública
 */
export async function uploadUserPlayerImage(file, userId, label = "player") {
  const timestamp = Date.now();
  const safeLabel = sanitizeFileName(label);
  const fileName = `${safeLabel}-${timestamp}`;
  const objectPath = `${userId}/${fileName}`;

  const { error: uploadError } = await supabase.storage
    .from("player-images")
    .upload(objectPath, file, {
      upsert: true,
    });

  if (uploadError) throw uploadError;

  const { data } = supabase.storage
    .from("player-images")
    .getPublicUrl(objectPath);
  return data.publicUrl;
}

/**
 * Extrae el path del objeto en Storage a partir de una URL pública.
 * Soporta URLs tipo:
 * https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>
 * @param {string} publicUrl
 * @param {string} bucket
 * @returns {string|null}
 */
export function extractStoragePathFromPublicUrl(
  publicUrl,
  bucket = "player-images"
) {
  if (!publicUrl) return null;
  const marker = `/object/public/${bucket}/`;
  const idx = publicUrl.indexOf(marker);
  if (idx === -1) return null;
  const path = publicUrl.slice(idx + marker.length);
  return path ? decodeURIComponent(path) : null;
}

/**
 * Elimina una imagen del bucket 'player-images' usando su URL pública (best-effort).
 * Requiere policy de Storage para DELETE por uid/%.
 * @param {string|null} publicUrl
 */
export async function deleteUserPlayerImageByPublicUrl(publicUrl) {
  const path = extractStoragePathFromPublicUrl(publicUrl, "player-images");
  if (!path) return;

  const { error } = await supabase.storage.from("player-images").remove([path]);
  if (error) throw error;
}

/**
 * Reemplaza el avatar del perfil (tabla public.profiles).
 * 1) intenta borrar avatar_url anterior
 * 2) sube nueva imagen a Storage (player-images/<uid>/...)
 * 3) actualiza profiles.avatar_url
 * @param {File} file
 * @param {string} label
 * @returns {Promise<object>} profile actualizado
 */
export async function replaceMyProfileAvatar(file, label = "vip") {
  const current = await getMyProfile();
  if (!current) throw new Error("No hay perfil cargado");

  if (current.avatar_url) {
    try {
      await deleteUserPlayerImageByPublicUrl(current.avatar_url);
    } catch (e) {
      console.warn("[Storage] No se pudo borrar el avatar anterior:", e);
    }
  }

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) throw userError;
  if (!user) throw new Error("No hay sesión activa");

  const newUrl = await uploadUserPlayerImage(file, user.id, label);
  return await updateMyProfile({ avatar_url: newUrl });
}

/**
 * Reemplaza la imagen del jugador del usuario autenticado:
 * 1) intenta borrar la imagen anterior
 * 2) sube la nueva imagen
 * 3) actualiza players.image_url
 * @param {File} file
 * @param {string} label
 * @returns {Promise<object>} player actualizado
 */
export async function replaceMyPlayerImage(file, label = "player") {
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) throw userError;
  if (!user) throw new Error("No hay sesión activa");

  const current = await getMyPlayer();
  if (!current) throw new Error("No existe un jugador asociado a esta cuenta");

  // Best-effort: si no se puede borrar (por policy o path), seguimos igual.
  if (current.image_url) {
    try {
      await deleteUserPlayerImageByPublicUrl(current.image_url);
    } catch (e) {
      console.warn("[Storage] No se pudo borrar la imagen anterior:", e);
    }
  }

  const newUrl = await uploadUserPlayerImage(file, user.id, label);
  const { data, error } = await supabase
    .from("players")
    .update({ image_url: newUrl })
    .eq("id", current.id)
    .select("*")
    .single();

  if (error) throw error;
  return data;
}

/**
 * Obtener el jugador asociado al usuario autenticado (players.user_id)
 * @returns {Promise<object|null>}
 */
export async function getMyPlayer() {
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) throw userError;
  if (!user) return null;

  const { data, error } = await supabase
    .from("players")
    .select("*")
    .eq("user_id", user.id)
    .maybeSingle();

  if (error) throw error;
  return data;
}

/**
 * Crear (si no existe) o actualizar el jugador del usuario actual.
 * Nota: no toca vidas (eso lo maneja el admin).
 * @param {{first_name: string, last_name: string, imageFile?: File|null}} payload
 */
export async function upsertMyPlayer(payload) {
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) throw userError;
  if (!user) throw new Error("No hay sesión activa");

  const firstName = (payload.first_name || "").trim();
  const lastName = (payload.last_name || "").trim();
  const display = `${firstName} ${lastName}`.trim();
  const nickname = display || user.email || "Jugador";

  const current = await getMyPlayer();

  let imageUrl = current?.image_url || null;
  if (payload.imageFile) {
    imageUrl = await uploadUserPlayerImage(
      payload.imageFile,
      user.id,
      display || user.email || "player"
    );
  }

  if (!current) {
    const { data, error } = await supabase
      .from("players")
      .insert({
        user_id: user.id,
        first_name: firstName,
        last_name: lastName,
        nickname,
        image_url: imageUrl,
      })
      .select("*")
      .single();

    if (error) throw error;
    return data;
  }

  const { data, error } = await supabase
    .from("players")
    .update({
      first_name: firstName,
      last_name: lastName,
      nickname,
      image_url: imageUrl,
    })
    .eq("id", current.id)
    .select("*")
    .single();

  if (error) throw error;
  return data;
}

/**
 * Subir imagen a Storage
 * @param {File} file
 * @param {string} playerNickname
 * @returns {Promise<string>} URL pública de la imagen
 */
export async function uploadPlayerImage(file, playerNickname) {
  const timestamp = Date.now();
  const sanitizedName = sanitizeFileName(playerNickname);
  const fileName = `${sanitizedName}-${timestamp}`;

  const { error: uploadError } = await supabase.storage
    .from("player-images")
    .upload(fileName, file);

  if (uploadError) throw uploadError;

  // Obtener URL pública
  const { data } = supabase.storage
    .from("player-images")
    .getPublicUrl(fileName);

  return data.publicUrl;
}

/**
 * Crear un nuevo jugador con imagen
 * @param {string} nickname
 * @param {File} imageFile (opcional)
 */
export async function createPlayer(nickname, imageFile = null) {
  let imageUrl = null;

  // Si hay imagen, subirla primero
  if (imageFile) {
    try {
      imageUrl = await uploadPlayerImage(imageFile, nickname);
    } catch (error) {
      console.error("Error subiendo imagen:", error);
      // Continuar sin imagen si hay error
    }
  }

  const { data, error } = await supabase
    .from("players")
    .insert({
      nickname,
      lives: 12,
      max_lives: 12,
      image_url: imageUrl,
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Quitar vidas a un jugador (RPC function)
 * @param {number} playerId
 * @param {number} amount
 * @param {string} reason
 */
export async function removePlayerLives(playerId, amount, reason = "") {
  const { data, error } = await supabase.rpc("admin_remove_lives", {
    p_player_id: playerId,
    p_amount: amount,
    p_reason: reason,
  });

  if (error) throw error;
  return data;
}

/**
 * Resetear vidas de un jugador
 * @param {number} playerId
 */
export async function resetPlayerLives(playerId) {
  const { data, error } = await supabase.rpc("admin_reset_lives", {
    p_player_id: playerId,
  });

  if (error) throw error;
  return data;
}

/**
 * Resetear vidas de TODOS los jugadores
 */
export async function resetAllLives() {
  const { data, error } = await supabase.rpc("admin_reset_lives_all");

  if (error) throw error;
  return data;
}

/**
 * Obtener historial de eventos
 * @returns {Promise<Array>}
 */
export async function getLifeEvents() {
  const { data, error } = await supabase
    .from("life_events")
    .select(
      `
      *,
      player:players(nickname)
    `
    )
    .order("created_at", { ascending: false })
    .limit(100);

  if (error) throw error;
  return data || [];
}

/**
 * Eliminar un jugador
 * @param {number} playerId
 */
export async function deletePlayer(playerId) {
  const { error } = await supabase.from("players").delete().eq("id", playerId);

  if (error) throw error;
}
