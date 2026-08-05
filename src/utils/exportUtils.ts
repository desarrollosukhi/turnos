import * as XLSX from 'xlsx'
import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'

export function exportToCSV(data: Record<string, any>[], filename: string) {
  if (!data || data.length === 0) return

  const firstRow = data[0]
  if (!firstRow) return
  const headers = Object.keys(firstRow)
  const csvContent = [
    headers.join(','),
    ...data.map(row =>
      headers.map(h => {
        const val = row[h]
        if (val === null || val === undefined) return ''
        if (typeof val === 'string' && val.includes(',')) return `"${val}"`
        return val
      }).join(',')
    )
  ].join('\n')

  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })
  downloadBlob(blob, `${filename}.csv`)
}

export function exportToExcel(data: Record<string, any>[], filename: string, sheetName: string = 'Reporte') {
  if (data.length === 0) return

  const ws = XLSX.utils.json_to_sheet(data)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, sheetName)
  XLSX.writeFile(wb, `${filename}.xlsx`)
}

export function exportToPDF(data: Record<string, any>[], columns: { header: string; key: string }[], title: string, filename: string) {
  if (data.length === 0) return

  const doc = new jsPDF()

  doc.setFontSize(16)
  doc.text(title, 14, 22)

  doc.setFontSize(10)
  doc.text(`Fecha: ${new Date().toLocaleDateString('es-AR')}`, 14, 30)

  autoTable(doc, {
    startY: 38,
    head: [columns.map(c => c.header)],
    body: data.map(row => columns.map(c => row[c.key] ?? '')),
    styles: { fontSize: 8 },
    headStyles: { fillColor: [37, 99, 235] },
  })

  doc.save(`${filename}.pdf`)
}

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}

export function getDatePresets() {
  const today = new Date()
  const startOfWeek = new Date(today)
  startOfWeek.setDate(today.getDate() - today.getDay() + 1)
  const endOfWeek = new Date(startOfWeek)
  endOfWeek.setDate(startOfWeek.getDate() + 6)

  const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)
  const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0)

  const startOfYear = new Date(today.getFullYear(), 0, 1)
  const endOfYear = new Date(today.getFullYear(), 11, 31)

  const last7Days = new Date(today)
  last7Days.setDate(today.getDate() - 6)

  const last30Days = new Date(today)
  last30Days.setDate(today.getDate() - 29)

  return [
    { label: 'Esta semana', start: formatDate(startOfWeek), end: formatDate(endOfWeek) },
    { label: 'Este mes', start: formatDate(startOfMonth), end: formatDate(endOfMonth) },
    { label: 'Este año', start: formatDate(startOfYear), end: formatDate(endOfYear) },
    { label: 'Últimos 7 días', start: formatDate(last7Days), end: formatDate(today) },
    { label: 'Últimos 30 días', start: formatDate(last30Days), end: formatDate(today) },
  ]
}

function formatDate(date: Date): string {
  return date.toISOString().split('T')[0] ?? ''
}
