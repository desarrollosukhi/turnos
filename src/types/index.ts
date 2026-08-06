export type ModalidadType = 'in_person' | 'virtual'

export type BookingStatus = 'pending' | 'confirmed' | 'cancelled' | 'attended' | 'no_show'

export type DiaSemana = 'lunes' | 'martes' | 'miercoles' | 'jueves' | 'viernes' | 'sabado' | 'domingo'

export type UserRole = 'super_admin' | 'admin' | 'professional' | 'customer'

export type BusinessType = 'YOGA' | 'GYM' | 'PILATES' | 'HAIRDRESSER' | 'BARBER' | 'MEDICAL' | 'CUSTOM'

export type CustomerMode = 'MEMBER' | 'GUEST'

export type BookingMode = 'CLASS' | 'APPOINTMENT'

export interface Company {
  id: string
  name: string
  business_type: BusinessType
  gym_schedule: Record<string, { active: boolean; start: string; end: string } | null> | null
  active: boolean
  created_at: string
}

export interface CompanySettings {
  company_id: string
  customer_mode: CustomerMode
  booking_mode: BookingMode
  gym_mode: boolean
  enable_clinical_history: boolean
  manage_credits: boolean
  allow_virtual: boolean
  allow_public_booking: boolean
  require_login: boolean
  show_alias: boolean
  whatsapp: string | null
  logo_url: string | null
  minutos_ventana_reserva: number
  minutos_ventana_cancelacion: number
  theme_preset: string
  primary_color: string
  primary_hover: string
  primary_subtle: string
  background_color: string
  surface_color: string
  text_color: string
  border_radius: string
}

export type Frequency = 'weekly' | 'appointment' | 'one_time'

export interface FrequencyOption {
  value: Frequency
  label: string
  icon: string
  description: string
}

export const FREQUENCY_OPTIONS: FrequencyOption[] = [
  { value: 'weekly', label: 'Semanal', icon: '🔄', description: 'Se repite cada semana en los días seleccionados' },
  { value: 'appointment', label: 'Turnos', icon: '⏰', description: 'Turnos individuales con intervalo configurable' },
  { value: 'one_time', label: 'Evento', icon: '🎯', description: 'Evento único, fecha específica' },
]

export const ALL_DAYS: { value: DiaSemana; label: string; short: string }[] = [
  { value: 'lunes', label: 'Lunes', short: 'Lu' },
  { value: 'martes', label: 'Martes', short: 'Ma' },
  { value: 'miercoles', label: 'Miércoles', short: 'Mi' },
  { value: 'jueves', label: 'Jueves', short: 'Ju' },
  { value: 'viernes', label: 'Viernes', short: 'Vi' },
  { value: 'sabado', label: 'Sábado', short: 'Sa' },
  { value: 'domingo', label: 'Domingo', short: 'Do' },
]

export type AccessType = 'credits' | 'free_pass'

export interface FreePass {
  id: string
  user_id: string
  company_id: string
  pass_type: 'monthly' | 'credits'
  credits_total: number | null
  credits_used: number
  start_date: string
  end_date: string
  active: boolean
  created_at: string
}

export interface ClinicalHistoryField {
  id: string
  company_id: string
  field_name: string
  field_type: 'text' | 'select' | 'date'
  is_required: boolean
  sort_order: number
  active: boolean
  created_at: string
}

export interface ClinicalHistoryEntry {
  id: string
  user_id: string
  company_id: string
  professional_id: string
  booking_id: string | null
  field_values: Record<string, string>
  free_text: string | null
  created_at: string
  updated_at: string
}

export interface ThemePreset {
  id: string
  name: string
  primary_color: string
  primary_hover: string
  primary_subtle: string
  background_color: string
  surface_color: string
  text_color: string
  border_radius: string
}

export interface User {
  id: string
  company_id: string | null
  name: string
  email: string
  phone: string | null
  birth_date: string | null
  emergency_contact_name: string | null
  emergency_contact_phone: string | null
  credits: number
  access_type: AccessType
  active: boolean
  has_account: boolean
  role: UserRole
  created_at: string
}

export interface Professional {
  id: string
  company_id: string
  user_id: string | null
  name: string
  alias: string | null
  email: string | null
  phone: string | null
  whatsapp: string | null
  active: boolean
}

export interface Resource {
  id: string
  company_id: string
  name: string
  type: string | null
  capacity: number | null
  active: boolean
}

export interface Service {
  id: string
  company_id: string
  professional_id: string
  resource_id: string | null
  name: string
  frequency: 'weekly' | 'appointment' | 'one_time'
  day_of_week: DiaSemana | null
  days_of_week: DiaSemana[] | null
  start_time: string
  end_time: string
  duration_minutes: number | null
  slot_interval_minutes: number | null
  appointment_start: string | null
  appointment_end: string | null
  event_date: string | null
  event_end_date: string | null
  allows_in_person: boolean
  allows_virtual: boolean
  in_person_capacity: number | null
  virtual_capacity: number | null
  active: boolean
}

export interface Booking {
  id: string
  user_id: string | null
  service_id: string
  date: string
  modality: ModalidadType | null
  status: BookingStatus
  guest_name: string | null
  guest_phone: string | null
  created_at: string
}

export interface CreditMovement {
  id: string
  user_id: string
  amount: number
  description: string
  expires_at: string | null
  created_at: string
}

export interface CancelledServiceSession {
  id: string
  company_id: string
  service_id: string
  date: string
  reason: string | null
  cancelled_by: string | null
  created_at: string
}

export interface Holiday {
  id: string
  company_id: string
  date: string
  name: string
  active: boolean
  created_at: string
}

export type AnnouncementTarget = 'all' | 'service_bookings'

export interface Announcement {
  id: string
  company_id: string
  professional_id: string | null
  service_id: string | null
  title: string
  content: string
  target: AnnouncementTarget
  date_from: string
  date_to: string | null
  active: boolean
  reactivated_at?: string | null
  created_at: string
}

export interface AnnouncementWithDetails extends Announcement {
  professional_name: string
  service_name: string | null
}

export interface BookingWindow {
  puede_reservar: boolean
  puede_cancelar: boolean
  minutos_para_clase: number
  ventana_reserva: number
  ventana_cancelacion: number
  clase_cancelada: boolean
  es_feriado: boolean
}

export interface ServiceWithProfessional extends Service {
  professionals: Professional
}

export interface BookingWithDetails extends Booking {
  services: ServiceWithProfessional
  users: User
}

export interface ClassAvailability {
  service_id: string
  date: string
  in_person_capacity_available: number
  virtual_capacity_available: number
  total_in_person_bookings: number
  total_virtual_bookings: number
}

export interface CancelledServiceSessionWithService extends CancelledServiceSession {
  services: ServiceWithProfessional
}

// Report types
export interface ReportBookingsByProfessional {
  professional_name: string
  total_reservations: number
  attended: number
  no_show: number
  cancelled: number
  attendance_rate: number
}

export interface ReportOccupancy {
  service_name: string
  professional_name: string
  total_bookings: number
  total_capacity: number
  occupancy_rate: number
}

export interface ReportCreditConsumption {
  customer_name: string
  credits_consumed: number
  credits_added: number
  net_balance: number
}

export interface ReportAttendanceRate {
  period: string
  total_reservations: number
  attended: number
  no_show: number
  cancelled: number
  attendance_rate: number
}

export interface ReportCustomerGrowth {
  month: string
  new_customers: number
}

export interface ReportServicePopularity {
  service_name: string
  professional_name: string
  total_reservations: number
  percentage: number
}

export interface ReportCancellation {
  cancellation_date: string
  service_name: string
  professional_name: string
  reason: string | null
}

export interface ReportMyBookings {
  service_name: string
  professional_name: string
  booking_date: string
  modality: ModalidadType | null
  status: BookingStatus
}

export type ReportType =
  | 'bookings_by_professional'
  | 'occupancy'
  | 'credit_consumption'
  | 'attendance_rate'
  | 'customer_growth'
  | 'service_popularity'
  | 'cancellations'
  | 'my_bookings'

// Business type display names
export const BUSINESS_TYPE_LABELS: Record<BusinessType, { professionals: string; services: string; customers: string }> = {
  YOGA: { professionals: 'Profesores', services: 'Clases', customers: 'Alumnos' },
  GYM: { professionals: 'Entrenadores', services: 'Clases', customers: 'Alumnos' },
  PILATES: { professionals: 'Profesores', services: 'Clases', customers: 'Alumnos' },
  HAIRDRESSER: { professionals: 'Peluqueros', services: 'Servicios', customers: 'Clientes' },
  BARBER: { professionals: 'Barberos', services: 'Servicios', customers: 'Clientes' },
  MEDICAL: { professionals: 'Profesionales', services: 'Turnos', customers: 'Pacientes' },
  CUSTOM: { professionals: 'Profesionales', services: 'Servicios', customers: 'Clientes' },
}

export function getProfessionalDisplayName(professional: Professional, showAlias: boolean): string {
  if (showAlias && professional.alias) return professional.alias
  return professional.name
}

export function getBusinessLabels(businessType: BusinessType) {
  return BUSINESS_TYPE_LABELS[businessType] || BUSINESS_TYPE_LABELS.CUSTOM
}

export const BUSINESS_TYPE_SPANISH: Record<BusinessType, string> = {
  YOGA: 'Yoga',
  GYM: 'Gimnasio',
  PILATES: 'Pilates',
  HAIRDRESSER: 'Peluquería',
  BARBER: 'Barbería',
  MEDICAL: 'Consultorio',
  CUSTOM: 'Otro',
}

export function getBusinessTypeSpanish(businessType: BusinessType): string {
  return BUSINESS_TYPE_SPANISH[businessType] || 'Otro'
}
