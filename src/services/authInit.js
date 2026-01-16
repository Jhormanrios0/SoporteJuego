import { ref } from "vue";
import { getSession } from "./supabase";

export const authInitializing = ref(true);

export async function initAuth() {
  authInitializing.value = true;
  try {
    await getSession();
  } catch (e) {
    // ignore
  } finally {
    authInitializing.value = false;
  }
}
