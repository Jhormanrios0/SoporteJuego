<template>
  <div class="birthday-container">
    <div v-if="!isEditing" class="view-mode">
      <div class="info-item">
        <span class="label">Tipo de Sangre:</span>
        <span class="value">{{ bloodType || 'No especificado' }}</span>
      </div>
      <div class="info-item">
        <span class="label">Fecha de Nacimiento:</span>
        <span class="value">{{ birthDate || 'No especificada' }}</span>
      </div>
      <div class="info-item">
        <span class="label">Edad:</span>
        <span class="value age-value">{{ calculatedAge !== null ? `${calculatedAge} años` : 'N/A' }}</span>
      </div>
      <button class="edit-btn" @click="startEdit" :disabled="isLoading">
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
          <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
        </svg>
        Editar
      </button>
    </div>

    <!-- MODO EDICIÓN -->
    <div v-else class="edit-mode">
      <div class="form-group">
        <label for="blood-type">Tipo de Sangre</label>
        <div class="blood-type-wrapper" @click.stop>
          <button 
            type="button"
            class="blood-type-btn"
            @click="toggleBloodTypePicker"
            :title="tempBloodType || 'Selecciona tipo de sangre'"
          >
            <!-- Gota de sangre 8-bits retro -->
            <svg class="blood-drop-icon" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2c0 0-6 7-6 11c0 3.3 2.7 6 6 6s6-2.7 6-6C18 9 12 2 12 2z" opacity="0.8"/>
              <circle cx="12" cy="11" r="2" fill="rgba(255,255,255,0.5)"/>
            </svg>
            <span class="blood-type-text">{{ tempBloodType || 'Seleccionar' }}</span>
          </button>
          
          <!-- Selector tipo de sangre -->
          <Transition name="picker-fade">
            <div v-if="showBloodTypePicker" class="blood-type-popup" @click.stop>
              <div class="blood-types-grid">
                <button 
                  v-for="type in bloodTypes" 
                  :key="type"
                  type="button"
                  class="blood-type-option"
                  :class="{ 'selected': tempBloodType === type }"
                  @click="selectBloodType(type)"
                >
                  {{ type }}
                </button>
              </div>
            </div>
          </Transition>
        </div>
        <input 
          v-model="tempBloodType" 
          id="blood-type"
          type="hidden" 
        />
      </div>

      <div class="form-group">
        <label for="birth-date">Fecha de Nacimiento</label>
        <div class="date-picker-wrapper" @click.stop>
          <button 
            type="button"
            class="date-picker-btn"
            @click="toggleDatePicker"
            :title="tempBirthDate || 'Selecciona fecha'"
          >
            <!-- Calendario 8-bits retro -->
            <svg class="calendar-icon" viewBox="0 0 24 24" fill="currentColor">
              <rect x="3" y="4" width="18" height="16" fill="none" stroke="currentColor" stroke-width="1.5" />
              <line x1="7" y1="4" x2="7" y2="2" stroke="currentColor" stroke-width="1.5" />
              <line x1="17" y1="4" x2="17" y2="2" stroke="currentColor" stroke-width="1.5" />
              <line x1="3" y1="8" x2="21" y2="8" stroke="currentColor" stroke-width="1.5" />
              <!-- Días -->
              <rect x="3" y="8" width="3" height="3" fill="currentColor" opacity="0.6" />
              <rect x="7" y="8" width="3" height="3" fill="currentColor" opacity="0.4" />
              <rect x="11" y="8" width="3" height="3" fill="currentColor" opacity="0.6" />
              <rect x="15" y="8" width="3" height="3" fill="currentColor" opacity="0.4" />
              <rect x="3" y="12" width="3" height="3" fill="currentColor" opacity="0.5" />
              <rect x="7" y="12" width="3" height="3" fill="currentColor" opacity="0.6" />
            </svg>
            <span class="date-text">{{ tempBirthDate ? formatDateDisplay(tempBirthDate) : 'Seleccionar' }}</span>
          </button>
          
          <!-- Picker popup -->
          <Transition name="calendar-fade">
            <div v-if="showDatePicker" class="calendar-popup" @click.stop>
              <div class="calendar-header">
                <select v-model.number="pickerMonth" class="month-select">
                  <option v-for="(month, idx) in months" :key="idx" :value="idx">
                    {{ month.substring(0, 3) }}
                  </option>
                </select>
                <select v-model.number="pickerYear" class="year-select">
                  <option v-for="year in yearRange" :key="year" :value="year">
                    {{ year }}
                  </option>
                </select>
              </div>
              <div class="calendar-grid">
                <div v-for="day in ['Do', 'Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa']" :key="day" class="day-header">
                  {{ day }}
                </div>
                <button 
                  v-for="day in calendarDays" 
                  :key="`${day.month}-${day.date}`"
                  type="button"
                  class="day-btn"
                  :class="{ 
                    'other-month': !day.currentMonth,
                    'selected': day.selected,
                    'today': day.isToday
                  }"
                  @click="selectDate(day)"
                  :disabled="!day.currentMonth"
                >
                  {{ day.date }}
                </button>
              </div>
            </div>
          </Transition>
        </div>
        <input 
          v-model="tempBirthDate" 
          id="birth-date"
          type="hidden" 
        />
      </div>

      <div v-if="tempBirthDate" class="preview-age">
        <span class="label">Edad (preview):</span>
        <span class="value">{{ calculateAge(tempBirthDate) }} años</span>
      </div>

      <div v-if="errorMsg" class="error-msg">{{ errorMsg }}</div>

      <div class="button-group">
        <button class="btn-save" @click="saveData" :disabled="isLoading">
          {{ isLoading ? 'Guardando...' : 'Guardar' }}
        </button>
        <button class="btn-cancel" @click="cancelEdit" :disabled="isLoading">
          Cancelar
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { supabase } from '@/services/supabase';

const props = defineProps({
  profile: {
    type: Object,
    default: null
  }
});

const emit = defineEmits(['update']);

// Estado
const isEditing = ref(false);
const isLoading = ref(false);
const errorMsg = ref('');

// Datos actuales
const bloodType = ref('');
const birthDate = ref('');

// Datos temporales en edición
const tempBloodType = ref('');
const tempBirthDate = ref('');

// Calendar state
const showDatePicker = ref(false);
const pickerMonth = ref(new Date().getMonth());
const pickerYear = ref(new Date().getFullYear());

// Blood type state
const showBloodTypePicker = ref(false);
const bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

// Trigger para forzar recalculación de edad
const currentTime = ref(new Date());

// Edad calculada
const calculatedAge = computed(() => {
  // Usar currentTime como dependencia para forzar recalculación
  currentTime.value; // Acceso a la propiedad reactiva
  return calculateAge(birthDate.value);
});

// Funciones
function calculateAge(date) {
  if (!date) return null;
  
  const today = new Date();
  const bday = new Date(date);
  
  let age = today.getFullYear() - bday.getFullYear();
  const monthDiff = today.getMonth() - bday.getMonth();
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < bday.getDate())) {
    age--;
  }
  
  return age;
}

const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
                'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

const yearRange = computed(() => {
  const currentYear = new Date().getFullYear();
  const years = [];
  for (let i = currentYear - 100; i <= currentYear; i++) {
    years.push(i);
  }
  return years;
});

const monthYearDisplay = computed(() => {
  return `${months[pickerMonth.value]} ${pickerYear.value}`;
});

const calendarDays = computed(() => {
  const firstDay = new Date(pickerYear.value, pickerMonth.value, 1);
  const lastDay = new Date(pickerYear.value, pickerMonth.value + 1, 0);
  const prevLastDay = new Date(pickerYear.value, pickerMonth.value, 0);
  
  const firstDayOfWeek = firstDay.getDay();
  const daysInMonth = lastDay.getDate();
  const daysInPrevMonth = prevLastDay.getDate();
  
  const days = [];
  
  // Días del mes anterior
  for (let i = firstDayOfWeek - 1; i >= 0; i--) {
    days.push({
      date: daysInPrevMonth - i,
      currentMonth: false,
      month: pickerMonth.value - 1,
      selected: false,
      isToday: false
    });
  }
  
  // Días del mes actual
  const today = new Date();
  for (let i = 1; i <= daysInMonth; i++) {
    const d = new Date(pickerYear.value, pickerMonth.value, i);
    const dateStr = d.toISOString().split('T')[0];
    const isSelected = tempBirthDate.value === dateStr;
    const isToday = d.toDateString() === today.toDateString();
    
    days.push({
      date: i,
      currentMonth: true,
      month: pickerMonth.value,
      selected: isSelected,
      isToday: isToday,
      fullDate: dateStr
    });
  }
  
  // Días del próximo mes
  const remainingDays = 42 - days.length;
  for (let i = 1; i <= remainingDays; i++) {
    days.push({
      date: i,
      currentMonth: false,
      month: pickerMonth.value + 1,
      selected: false,
      isToday: false
    });
  }
  
  return days;
});

function toggleDatePicker() {
  showDatePicker.value = !showDatePicker.value;
}

function toggleBloodTypePicker() {
  showBloodTypePicker.value = !showBloodTypePicker.value;
}

function selectBloodType(type) {
  tempBloodType.value = type;
  showBloodTypePicker.value = false;
}

function selectDate(day) {
  if (day.fullDate) {
    tempBirthDate.value = day.fullDate;
    showDatePicker.value = false;
  }
}

function formatDateDisplay(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr + 'T00:00:00');
  return d.toLocaleDateString('es-ES', { year: 'numeric', month: 'long', day: 'numeric' });
}

function startEdit() {
  tempBloodType.value = bloodType.value;
  tempBirthDate.value = birthDate.value;
  isEditing.value = true;
  errorMsg.value = '';
}

function cancelEdit() {
  isEditing.value = false;
  errorMsg.value = '';
}

async function loadData() {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    
    if (!user) return;

    const { data, error } = await supabase
      .from('profiles')
      .select('blood_type, birth_date')
      .eq('id', user.id)
      .single();

    if (error) throw error;

    if (data) {
      bloodType.value = data.blood_type || '';
      birthDate.value = data.birth_date || '';
    }
  } catch (error) {
    console.error('Error cargando datos del perfil:', error);
  }
}

async function saveData() {
  isLoading.value = true;
  errorMsg.value = '';

  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    
    if (!user) throw new Error('No hay usuario autenticado');

    const { error } = await supabase
      .from('profiles')
      .update({
        blood_type: tempBloodType.value || null,
        birth_date: tempBirthDate.value || null
      })
      .eq('id', user.id);

    if (error) throw error;

    // Actualizar valores locales con lo que se guardó
    bloodType.value = tempBloodType.value;
    birthDate.value = tempBirthDate.value;
    isEditing.value = false;

    emit('update', {
      bloodType: bloodType.value,
      birthDate: birthDate.value,
      age: calculatedAge.value
    });
  } catch (error) {
    console.error('Error guardando datos:', error);
    errorMsg.value = 'Error al guardar los datos. Intenta de nuevo.';
  } finally {
    isLoading.value = false;
  }
}

// Lifecycle
onMounted(() => {
  loadData();
  
  // Actualizar tiempo cada minuto para recalcular edad en tiempo real
  const interval = setInterval(() => {
    currentTime.value = new Date();
  }, 60000);
  
  // Cerrar calendar al hacer click fuera
  const handleClickOutside = (e) => {
    if (showDatePicker.value && !e.target.closest('.date-picker-wrapper')) {
      showDatePicker.value = false;
    }
    if (showBloodTypePicker.value && !e.target.closest('.blood-type-wrapper')) {
      showBloodTypePicker.value = false;
    }
  };
  
  document.addEventListener('click', handleClickOutside);
  
  onUnmounted(() => {
    clearInterval(interval);
    document.removeEventListener('click', handleClickOutside);
  });
});

watch(() => props.profile, (newPlayer) => {
  
  if (newPlayer && !isEditing.value) {
    const newBloodType = newPlayer.blood_type || '';
    const newBirthDate = newPlayer.birth_date || '';
    
    // Comparar valores antes de actualizar
    if (newBloodType !== bloodType.value || 
        newBirthDate !== birthDate.value) {
      // Solo actualizar si hay cambio
      bloodType.value = newBloodType;
      birthDate.value = newBirthDate;
    }
  }
}, { deep: true });
</script>

<style scoped>
.birthday-container {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 6px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

/* MODO VISUALIZACIÓN */
.view-mode {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.info-item:last-of-type {
  border-bottom: none;
}

.label {
  font-size: 12px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.6);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.value {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.9);
  font-weight: 500;
}

.age-value {
  color: #4CAF50;
  font-weight: 600;
}

.edit-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: rgba(76, 175, 80, 0.1);
  border: 1px solid rgba(76, 175, 80, 0.3);
  border-radius: 4px;
  color: #4CAF50;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.edit-btn:hover:not(:disabled) {
  background: rgba(76, 175, 80, 0.2);
  border-color: rgba(76, 175, 80, 0.6);
}

.edit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.icon {
  width: 12px;
  height: 12px;
}

/* MODO EDICIÓN */
.edit-mode {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group label {
  font-size: 12px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.7);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.input-field {
  padding: 8px 10px;
  background: rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 4px;
  color: rgba(255, 255, 255, 0.9);
  font-size: 13px;
  transition: all 0.2s ease;
}

.input-field:hover {
  border-color: rgba(255, 255, 255, 0.4);
  background: rgba(0, 0, 0, 0.4);
}

.input-field:focus {
  outline: none;
  border-color: #4CAF50;
  background: rgba(0, 0, 0, 0.5);
  box-shadow: 0 0 8px rgba(76, 175, 80, 0.2);
}

.preview-age {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 10px;
  background: rgba(76, 175, 80, 0.1);
  border: 1px solid rgba(76, 175, 80, 0.2);
  border-radius: 4px;
  font-size: 12px;
}

.preview-age .label {
  color: rgba(76, 175, 80, 0.9);
}

.preview-age .value {
  color: #4CAF50;
  font-weight: 600;
}

.error-msg {
  padding: 8px 10px;
  background: rgba(244, 67, 54, 0.1);
  border: 1px solid rgba(244, 67, 54, 0.3);
  border-radius: 4px;
  color: #ff6b6b;
  font-size: 12px;
}

.button-group {
  display: flex;
  gap: 8px;
  margin-top: 4px;
}

.btn-save,
.btn-cancel {
  flex: 1;
  padding: 8px 12px;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-save {
  background: rgba(76, 175, 80, 0.2);
  border: 1px solid rgba(76, 175, 80, 0.4);
  color: #4CAF50;
}

.btn-save:hover:not(:disabled) {
  background: rgba(76, 175, 80, 0.3);
  border-color: rgba(76, 175, 80, 0.6);
}

.btn-cancel {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: rgba(255, 255, 255, 0.8);
}

.btn-cancel:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.15);
  border-color: rgba(255, 255, 255, 0.3);
}

.btn-save:disabled,
.btn-cancel:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* CALENDAR STYLES */
.date-picker-wrapper {
  position: relative;
}

.date-picker-btn {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  background: rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(76, 175, 80, 0.4);
  border-radius: 4px;
  color: rgba(255, 255, 255, 0.9);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s ease;
  font-weight: 500;
  text-align: left;
}

.date-picker-btn:hover {
  border-color: #4CAF50;
  background: rgba(0, 0, 0, 0.4);
}

.date-picker-btn:focus {
  outline: none;
  border-color: #4CAF50;
  background: rgba(0, 0, 0, 0.5);
  box-shadow: 0 0 8px rgba(76, 175, 80, 0.2);
}

.calendar-icon {
  width: 16px;
  height: 16px;
  flex-shrink: 0;
  color: #4CAF50;
}

.date-text {
  flex: 1;
  min-width: 0;
}

.calendar-popup {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  margin-top: 6px;
  background: rgba(0, 0, 0, 0.85);
  border: 2px solid rgba(76, 175, 80, 0.5);
  border-radius: 6px;
  padding: 8px;
  z-index: 100;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6),
              inset 0 0 0 1px rgba(76, 175, 80, 0.2);
  max-width: 280px;
}

.calendar-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  margin-bottom: 8px;
  padding-bottom: 6px;
  border-bottom: 1px solid rgba(76, 175, 80, 0.3);
}

.month-select,
.year-select {
  padding: 4px 6px;
  background: rgba(0, 0, 0, 0.4);
  border: 1px solid rgba(76, 175, 80, 0.4);
  border-radius: 3px;
  color: rgba(255, 255, 255, 0.8);
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  font-family: "Press Start 2P", monospace;
  letter-spacing: 0.3px;
}

.month-select:hover,
.year-select:hover {
  border-color: #4CAF50;
  background: rgba(76, 175, 80, 0.15);
  color: #4CAF50;
}

.month-select:focus,
.year-select:focus {
  outline: none;
  border-color: #4CAF50;
  background: rgba(76, 175, 80, 0.2);
  box-shadow: 0 0 8px rgba(76, 175, 80, 0.3);
}

.month-select option,
.year-select option {
  background: rgba(0, 0, 0, 0.9);
  color: rgba(255, 255, 255, 0.8);
  font-family: "Press Start 2P", monospace;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  background: rgba(0, 0, 0, 0.4);
  padding: 4px;
  border-radius: 3px;
}

.day-header {
  font-size: 9px;
  font-weight: 600;
  color: rgba(76, 175, 80, 0.7);
  text-align: center;
  padding: 2px 0;
  text-transform: uppercase;
  letter-spacing: 0.2px;
  font-family: "Press Start 2P", monospace;
}

.day-btn {
  aspect-ratio: 1 / 1;
  padding: 2px;
  background: rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(76, 175, 80, 0.2);
  border-radius: 2px;
  color: rgba(255, 255, 255, 0.6);
  font-size: 10px;
  cursor: pointer;
  transition: all 0.15s ease;
  font-weight: 500;
  display: flex;
  align-items: center;
  justify-content: center;
}

.day-btn:not(:disabled):hover {
  background: rgba(76, 175, 80, 0.2);
  border-color: rgba(76, 175, 80, 0.5);
  color: #4CAF50;
  transform: scale(1.08);
  box-shadow: 0 0 6px rgba(76, 175, 80, 0.3);
}

.day-btn:not(:disabled):active {
  transform: scale(0.92);
}

.day-btn.other-month {
  opacity: 0.25;
  cursor: not-allowed;
}

.day-btn.other-month:hover {
  transform: none;
}

.day-btn.selected {
  background: rgba(76, 175, 80, 0.4);
  border: 1px solid rgba(76, 175, 80, 0.8);
  color: #4CAF50;
  font-weight: 600;
  box-shadow: 0 0 10px rgba(76, 175, 80, 0.4),
              inset 0 0 6px rgba(76, 175, 80, 0.2);
}

.day-btn.today {
  border: 1px solid rgba(255, 218, 121, 0.6);
  color: #ffda79;
}

.day-btn.today.selected {
  background: rgba(255, 218, 121, 0.2);
  border: 1px solid rgba(255, 218, 121, 0.8);
  color: #ffda79;
  box-shadow: 0 0 10px rgba(255, 218, 121, 0.3),
              inset 0 0 6px rgba(255, 218, 121, 0.1);
}

.calendar-fade-enter-active,
.calendar-fade-leave-active {
  transition: all 0.2s ease;
}

.calendar-fade-enter-from,
.calendar-fade-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* BLOOD TYPE PICKER STYLES */
.blood-type-wrapper {
  position: relative;
}

.blood-type-btn {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  background: rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(244, 67, 54, 0.4);
  border-radius: 4px;
  color: rgba(255, 255, 255, 0.9);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s ease;
  font-weight: 500;
  text-align: left;
}

.blood-type-btn:hover {
  border-color: #ff6b6b;
  background: rgba(0, 0, 0, 0.4);
}

.blood-type-btn:focus {
  outline: none;
  border-color: #ff6b6b;
  background: rgba(0, 0, 0, 0.5);
  box-shadow: 0 0 8px rgba(244, 67, 54, 0.2);
}

.blood-drop-icon {
  width: 16px;
  height: 16px;
  flex-shrink: 0;
  color: #ff6b6b;
}

.blood-type-text {
  flex: 1;
  min-width: 0;
}

.blood-type-popup {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  margin-top: 6px;
  background: rgba(0, 0, 0, 0.85);
  border: 2px solid rgba(244, 67, 54, 0.5);
  border-radius: 6px;
  padding: 8px;
  z-index: 100;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6),
              inset 0 0 0 1px rgba(244, 67, 54, 0.2);
  max-width: 220px;
}

.blood-types-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 4px;
}

.blood-type-option {
  aspect-ratio: 1 / 1;
  padding: 4px;
  background: rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(244, 67, 54, 0.3);
  border-radius: 3px;
  color: rgba(255, 255, 255, 0.7);
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: "Press Start 2P", monospace;
}

.blood-type-option:hover {
  background: rgba(244, 67, 54, 0.2);
  border-color: rgba(244, 67, 54, 0.6);
  color: #ff6b6b;
  transform: scale(1.08);
  box-shadow: 0 0 8px rgba(244, 67, 54, 0.3);
}

.blood-type-option:active {
  transform: scale(0.92);
}

.blood-type-option.selected {
  background: rgba(244, 67, 54, 0.3);
  border: 1px solid rgba(244, 67, 54, 0.8);
  color: #ff6b6b;
  font-weight: 700;
  box-shadow: 0 0 10px rgba(244, 67, 54, 0.4),
              inset 0 0 6px rgba(244, 67, 54, 0.2);
}

.picker-fade-enter-active,
.picker-fade-leave-active {
  transition: all 0.2s ease;
}

.picker-fade-enter-from,
.picker-fade-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
