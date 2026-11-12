import { useMemo, useState } from 'react'
import {
  ArrowLeft,
  ArrowRight,
  Banknote,
  CalendarDays,
  Check,
  ChevronDown,
  Clock3,
  CreditCard,
  Dumbbell,
  Filter,
  LockKeyhole,
  Plus,
  ReceiptText,
  Search,
  ShieldCheck,
  Target,
  Volleyball,
  Wallet,
  X,
} from 'lucide-react'
import { Link } from 'react-router-dom'

const sports = [
  { name: 'Badminton', icon: Volleyball, rate: 8, facility: 'Badminton Court' },
  { name: 'Darts', icon: Target, rate: 4, facility: 'Darts Lane' },
  { name: 'Futsal', icon: Dumbbell, rate: 25, facility: 'Futsal Court' },
]

const courtsBySport = {
  Badminton: [
    { number: '01', status: 'available' },
    { number: '02', status: 'available' },
    { number: '03', status: 'booked' },
    { number: '04', status: 'locked' },
  ],
  Darts: [
    { number: '01', status: 'available' },
    { number: '02', status: 'booked' },
    { number: '03', status: 'available' },
    { number: '04', status: 'locked' },
  ],
  Futsal: [
    { number: '01', status: 'booked' },
    { number: '02', status: 'available' },
    { number: '03', status: 'locked' },
    { number: '04', status: 'available' },
  ],
}

const banks = [
  'Maybank2u',
  'CIMB Clicks',
  'Public Bank',
  'RHB Now',
  'Hong Leong Bank',
  'Bank Islam',
  'AmBank',
  'Bank Rakyat',
  'Affin Bank',
  'Alliance Bank',
  'BSN',
  'Bank Muamalat',
  'Agrobank',
  'OCBC Bank',
  'UOB Malaysia',
  'HSBC Bank Malaysia',
  'Standard Chartered',
  'Kuwait Finance House',
  'Al Rajhi Bank',
  'MBSB Bank',
]

const startTimes = ['9:00 AM', '10:00 AM', '11:00 AM', '1:00 PM', '2:00 PM', '3:00 PM', '5:00 PM', '6:00 PM', '7:00 PM', '8:00 PM', '9:00 PM']

function localDateValue(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function formatDate(value) {
  return new Date(`${value}T12:00:00`).toLocaleDateString('en-MY', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

function formatTimeRange(time, duration) {
  const [clock, period] = time.split(' ')
  const [hour, minute] = clock.split(':').map(Number)
  const startHour = hour % 12 + (period === 'PM' ? 12 : 0)
  const startMinutes = startHour * 60 + minute
  const endMinutes = (startMinutes + Number(duration) * 60) % (24 * 60)
  const endHour24 = Math.floor(endMinutes / 60)
  const endHour = endHour24 % 12 || 12
  const endPeriod = endHour24 >= 12 ? 'PM' : 'AM'
  const endMinute = String(endMinutes % 60).padStart(2, '0')
  return `${time} – ${endHour}:${endMinute} ${endPeriod}`
}

function formatMoney(amount) {
  return `RM ${amount.toFixed(2)}`
}

export function BookingPage() {
  const dateOptions = useMemo(() => Array.from({ length: 7 }, (_, index) => {
    const date = new Date()
    date.setDate(date.getDate() + index)
    return {
      value: localDateValue(date),
      label: `${index === 0 ? 'Today' : index === 1 ? 'Tomorrow' : date.toLocaleDateString('en-MY', { weekday: 'short' })} · ${date.toLocaleDateString('en-MY', { day: 'numeric', month: 'short' })}`,
    }
  }), [])
  const [step, setStep] = useState('selection')
  const [sport, setSport] = useState(sports[0].name)
  const [date, setDate] = useState(() => localDateValue(new Date()))
  const [time, setTime] = useState('9:00 PM')
  const [duration, setDuration] = useState('1')
  const [selectedCourt, setSelectedCourt] = useState(null)
  const [cart, setCart] = useState([])
  const [paymentMethod, setPaymentMethod] = useState('')
  const [bank, setBank] = useState('')
  const [paymentNotice, setPaymentNotice] = useState('')
  const selectedSport = sports.find((item) => item.name === sport)
  const selectedPrice = selectedSport.rate * Number(duration)
  const total = cart.reduce((sum, item) => sum + item.price, 0)

  function addToCart() {
    if (!selectedCourt) return
    setCart((items) => [...items, {
      id: `${Date.now()}-${Math.random()}`,
      sport,
      facility: selectedSport.facility,
      court: selectedCourt,
      date,
      time,
      duration: Number(duration),
      rate: selectedSport.rate,
      price: selectedPrice,
    }])
    setSelectedCourt(null)
  }

  function continueToPayment() {
    setPaymentMethod('')
    setBank('')
    setPaymentNotice('')
    setStep('payment')
  }

  function submitDemoPayment() {
    if (!paymentMethod || (paymentMethod === 'fpx' && !bank)) return
    setPaymentNotice('Payment preview only. No payment was submitted.')
  }

  const pageHeader = {
    selection: { number: '02', title: 'Choose your court', subtitle: 'Pick a sport, time and available court.' },
    review: { number: '03', title: 'Review your booking', subtitle: 'Check your selected courts before continuing.' },
    payment: { number: '04', title: 'Payment & booking status', subtitle: 'Select a payment method to continue.' },
  }[step]

  return (
    <div className="mx-auto max-w-5xl pb-32">
      <header className="mb-7 overflow-hidden rounded-2xl bg-[#1A3B2B] px-5 py-5 text-white shadow-sm sm:px-7">
        <div className="flex items-center gap-4">
          {step !== 'selection' && (
            <button
              type="button"
              onClick={() => setStep(step === 'payment' ? 'review' : 'selection')}
              className="grid h-10 w-10 shrink-0 place-items-center rounded-xl border border-white/15 bg-white/10 transition hover:bg-white/20"
              aria-label="Go back"
            >
              <ArrowLeft size={18} />
            </button>
          )}
          <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-white/10 text-sm font-bold text-[#d9f3c3]">
            {pageHeader.number}
          </div>
          <div>
            <p className="text-xs font-medium text-white/60">KRP PLAY · BOOKING</p>
            <h1 className="mt-0.5 text-lg font-bold tracking-tight sm:text-xl">{pageHeader.title}</h1>
            <p className="mt-1 text-xs text-white/70">{pageHeader.subtitle}</p>
          </div>
        </div>
      </header>

      {step === 'selection' && (
        <div className="space-y-5">
          <section className="rounded-2xl border border-[#e6ebe7] bg-white p-4 shadow-sm sm:p-6">
            <div className="mb-4 flex items-center gap-2 text-sm font-semibold text-[#1d3528]">
              <CalendarDays size={17} className="text-[#66865b]" />
              Choose your time
            </div>
            <div className="grid gap-3 sm:grid-cols-3">
              <label className="grid gap-1.5 text-xs font-semibold text-[#68756c]">
                Date
                <span className="relative">
                  <select value={date} onChange={(event) => setDate(event.target.value)} className="h-12 w-full appearance-none rounded-xl border border-[#e2e8e3] bg-[#fbfcfb] px-3 pr-9 text-sm font-medium text-[#273b2e] outline-none focus:border-[#527a55] focus:ring-2 focus:ring-[#527a55]/10">
                    {dateOptions.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
                  </select>
                  <ChevronDown size={16} className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-[#89958c]" />
                </span>
              </label>
              <label className="grid gap-1.5 text-xs font-semibold text-[#68756c]">
                Start time
                <span className="relative">
                  <select value={time} onChange={(event) => setTime(event.target.value)} className="h-12 w-full appearance-none rounded-xl border border-[#e2e8e3] bg-[#fbfcfb] px-3 pr-9 text-sm font-medium text-[#273b2e] outline-none focus:border-[#527a55] focus:ring-2 focus:ring-[#527a55]/10">
                    {startTimes.map((slot) => <option key={slot}>{slot}</option>)}
                  </select>
                  <ChevronDown size={16} className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-[#89958c]" />
                </span>
              </label>
              <label className="grid gap-1.5 text-xs font-semibold text-[#68756c]">
                Duration
                <span className="relative">
                  <select value={duration} onChange={(event) => setDuration(event.target.value)} className="h-12 w-full appearance-none rounded-xl border border-[#e2e8e3] bg-[#fbfcfb] px-3 pr-9 text-sm font-medium text-[#273b2e] outline-none focus:border-[#527a55] focus:ring-2 focus:ring-[#527a55]/10">
                    {[1, 2, 3].map((hours) => <option key={hours} value={hours}>{hours} {hours === 1 ? 'hour' : 'hours'}</option>)}
                  </select>
                  <ChevronDown size={16} className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-[#89958c]" />
                </span>
              </label>
            </div>
            <div className="mt-4 flex flex-wrap items-center justify-between gap-2 rounded-xl bg-[#f3f7f1] px-4 py-3 text-xs">
              <span className="flex items-center gap-2 text-[#617166]"><Clock3 size={15} />{formatTimeRange(time, duration)} <span className="text-[#aab4ac]">·</span> {formatDate(date)}</span>
              <strong className="text-[#254c34]">{formatMoney(selectedPrice)} <span className="font-normal text-[#708176]">per court</span></strong>
            </div>
          </section>

          <section className="rounded-2xl border border-[#e6ebe7] bg-white p-4 shadow-sm sm:p-6">
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 className="text-sm font-bold text-[#1d3528]">Choose a sport</h2>
                <p className="mt-1 text-xs text-[#8b978e]">Select a court to add it to your order.</p>
              </div>
              <span className="text-xs text-[#89958c]">Rate shown per hour</span>
            </div>
            <div role="tablist" aria-label="Sports" className="mb-5 flex gap-2 overflow-x-auto border-b border-[#edf0ed]">
              {sports.map(({ name, icon: Icon, rate }) => (
                <button key={name} type="button" role="tab" aria-selected={sport === name} onClick={() => { setSport(name); setSelectedCourt(null) }} className={`-mb-px flex shrink-0 items-center gap-2 border-b-2 px-3 py-3 text-sm font-semibold transition ${sport === name ? 'border-[#1A3B2B] text-[#1A3B2B]' : 'border-transparent text-[#89958c] hover:text-[#45584a]'}`}>
                  <Icon size={16} />{name}<span className="text-[11px] font-normal text-[#98a49a]">{formatMoney(rate)}/hr</span>
                </button>
              ))}
            </div>
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {courtsBySport[sport].map(({ number, status }) => {
                const isSelected = selectedCourt === number
                const disabled = status !== 'available'
                return (
                  <button
                    key={number}
                    type="button"
                    disabled={disabled}
                    onClick={() => setSelectedCourt(isSelected ? null : number)}
                    aria-pressed={isSelected}
                    className={`relative flex min-h-28 flex-col items-start justify-between rounded-xl border-2 p-3 text-left transition sm:p-4 ${status === 'booked' ? 'cursor-not-allowed border-[#f0c4bf] bg-[#fff9f8] text-[#a9564c]' : status === 'locked' ? 'cursor-not-allowed border-[#e7e9e7] bg-[#f5f6f5] text-[#a1aaa3]' : isSelected ? 'border-[#1A3B2B] bg-[#f0f7ed] ring-2 ring-[#1A3B2B]/10' : 'border-[#b6d1b3] bg-white text-[#294733] hover:border-[#1A3B2B] hover:bg-[#f8fbf7]'}`}
                  >
                    <span className="flex w-full items-center justify-between">
                      <span className="text-[10px] font-bold uppercase tracking-wider opacity-65">{selectedSport.facility}</span>
                      {status === 'locked' ? <LockKeyhole size={15} /> : isSelected ? <Check size={16} /> : null}
                    </span>
                    <span className="flex w-full items-end justify-between">
                      <span className="text-lg font-bold">Court {number}</span>
                      {status !== 'available' && <span className="text-[10px] font-semibold">{status === 'booked' ? 'Booked' : 'Locked'}</span>}
                    </span>
                  </button>
                )
              })}
            </div>
            {selectedCourt && (
              <div className="mt-4 flex flex-col gap-3 rounded-xl border border-[#dce8d9] bg-[#f7faf5] p-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <p className="text-[11px] font-medium uppercase tracking-wide text-[#849185]">Selected item</p>
                  <p className="mt-1 text-sm font-bold text-[#23412e]">{sport} {selectedSport.facility} {selectedCourt}</p>
                  <p className="mt-1 text-xs text-[#748177]">{formatDate(date)} · {formatTimeRange(time, duration)} · {formatMoney(selectedPrice)}</p>
                </div>
                <button type="button" onClick={addToCart} className="inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-[#1A3B2B] px-4 text-sm font-bold text-white transition hover:bg-[#28543b]">
                  Add to order <ArrowRight size={16} />
                </button>
              </div>
            )}
          </section>

          <div className="flex flex-wrap justify-center gap-5 text-[11px] text-[#7d8980]">
            <span className="flex items-center gap-2"><i className="h-2.5 w-2.5 rounded-full border border-[#7ea97d] bg-[#e8f4e5]" />Available</span>
            <span className="flex items-center gap-2"><i className="h-2.5 w-2.5 rounded-full border border-[#e0a09a] bg-[#fff0ee]" />Booked</span>
            <span className="flex items-center gap-2"><i className="h-2.5 w-2.5 rounded-full border border-[#d8dcda] bg-[#f0f1f0]" />Management locked</span>
          </div>
        </div>
      )}

      {step === 'review' && (
        <section className="rounded-2xl border border-[#e6ebe7] bg-white p-4 shadow-sm sm:p-6">
          <div className="mb-5 flex items-center justify-between gap-3">
            <div>
              <h2 className="text-base font-bold text-[#1d3528]">Your order</h2>
              <p className="mt-1 text-xs text-[#89958c]">{cart.length} {cart.length === 1 ? 'court' : 'courts'} selected</p>
            </div>
            <ReceiptText size={21} className="text-[#66865b]" />
          </div>
          {cart.length === 0 ? (
            <div className="rounded-xl border border-dashed border-[#dbe3dc] px-4 py-10 text-center">
              <p className="text-sm font-semibold text-[#425448]">Your order is empty</p>
              <p className="mt-1 text-xs text-[#89958c]">Go back and add an available court to continue.</p>
              <button type="button" onClick={() => setStep('selection')} className="mt-4 text-sm font-bold text-[#315d3d]">Choose a court</button>
            </div>
          ) : (
            <div className="space-y-3">
              {cart.map((item, index) => (
                <article key={item.id} className="rounded-xl border border-[#e9ede9] p-4">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="text-sm font-bold text-[#273b2e]">{item.sport} {item.facility} {item.court}</p>
                      <p className="mt-1.5 text-xs text-[#78857b]">{formatDate(item.date)} · {formatTimeRange(item.time, item.duration)}</p>
                    </div>
                    <button type="button" onClick={() => setCart((items) => items.filter((_, itemIndex) => itemIndex !== index))} className="grid h-8 w-8 shrink-0 place-items-center rounded-lg text-[#9a6a65] transition hover:bg-[#fff1ef]" aria-label={`Remove ${item.sport} Court ${item.court}`}>
                      <X size={16} />
                    </button>
                  </div>
                  <div className="mt-3 grid grid-cols-2 gap-3 border-t border-[#edf0ed] pt-3 text-xs sm:grid-cols-4">
                    <div><p className="text-[#98a29a]">Sport / facility</p><p className="mt-1 font-semibold text-[#536258]">{item.sport} · {item.facility} {item.court}</p></div>
                    <div><p className="text-[#98a29a]">Duration</p><p className="mt-1 font-semibold text-[#536258]">{item.duration} {item.duration === 1 ? 'hour' : 'hours'}</p></div>
                    <div><p className="text-[#98a29a]">Student category</p><p className="mt-1 font-semibold text-[#536258]">Non-KRP Student</p></div>
                    <div><p className="text-[#98a29a]">Rate</p><p className="mt-1 font-semibold text-[#536258]">{formatMoney(item.rate)} / hour</p></div>
                  </div>
                </article>
              ))}
            </div>
          )}
          <div className="mt-5 flex items-center justify-between rounded-xl bg-[#eef5e9] px-4 py-4">
            <span className="text-sm font-semibold text-[#45614b]">Total amount</span>
            <strong className="text-lg font-bold text-[#1A3B2B]">{formatMoney(total)}</strong>
          </div>
          <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-between">
            <button type="button" onClick={() => setStep('selection')} className="inline-flex h-12 items-center justify-center gap-2 rounded-xl border border-[#e1e7e1] px-5 text-sm font-semibold text-[#526258] hover:bg-[#f7f9f7]">
              <Plus size={16} /> Add another court
            </button>
            <button type="button" onClick={continueToPayment} disabled={cart.length === 0} className="inline-flex h-12 items-center justify-center gap-2 rounded-xl bg-[#1A3B2B] px-6 text-sm font-bold text-white transition hover:bg-[#28543b] disabled:cursor-not-allowed disabled:opacity-45">
              Proceed to payment <ArrowRight size={16} />
            </button>
          </div>
        </section>
      )}

      {step === 'payment' && (
        <div className="space-y-4">
          <section aria-label="Amount due" className="flex items-center justify-between gap-4 rounded-2xl border border-[#e6ebe7] bg-white p-5 shadow-sm sm:px-6">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-[#849185]">Amount due</p>
              <p className="mt-1 text-sm font-medium text-[#526258]">Booking total</p>
            </div>
            <strong className="text-2xl font-bold tracking-tight text-[#1A3B2B]">{formatMoney(total)}</strong>
          </section>

          <section className="rounded-2xl border border-[#e6ebe7] bg-white p-4 shadow-sm sm:p-6">
            <h2 className="mb-4 text-sm font-bold text-[#1d3528]">Select payment method</h2>
            <div className="space-y-3">
              <button type="button" aria-pressed={paymentMethod === 'fpx'} onClick={() => { setPaymentMethod('fpx'); setPaymentNotice('') }} className={`flex w-full items-center gap-3 rounded-xl border p-4 text-left transition ${paymentMethod === 'fpx' ? 'border-[#1A3B2B] bg-[#f5f9f3] ring-2 ring-[#1A3B2B]/10' : 'border-[#e5eae5] hover:border-[#b8c9b8]'}`}>
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#edf4e9] text-[#315a3b]"><Banknote size={20} /></span>
                <span className="flex-1"><strong className="block text-sm text-[#304137]">FPX Online Banking - All Malaysian banks</strong><small className="mt-1 block text-xs text-[#8b978e]">Choose your bank to continue</small></span>
                <span className={`h-4 w-4 rounded-full border ${paymentMethod === 'fpx' ? 'border-[5px] border-[#1A3B2B]' : 'border-[#cbd4cc]'}`} />
              </button>
              {paymentMethod === 'fpx' && (
                <label className="relative block pl-0 sm:pl-[52px]">
                  <span className="mb-1.5 block text-xs font-semibold text-[#68756c]">Choose your bank</span>
                  <select value={bank} onChange={(event) => setBank(event.target.value)} className="h-12 w-full appearance-none rounded-xl border border-[#e2e8e3] bg-white px-3 pr-10 text-sm text-[#273b2e] outline-none focus:border-[#527a55] focus:ring-2 focus:ring-[#527a55]/10">
                    <option value="">Select a bank</option>
                    {banks.map((name) => <option key={name}>{name}</option>)}
                  </select>
                  <ChevronDown size={16} className="pointer-events-none absolute bottom-3.5 right-3 text-[#89958c]" />
                </label>
              )}
              <button type="button" aria-pressed={paymentMethod === 'ewallet'} onClick={() => { setPaymentMethod('ewallet'); setBank(''); setPaymentNotice('') }} className={`flex w-full items-center gap-3 rounded-xl border p-4 text-left transition ${paymentMethod === 'ewallet' ? 'border-[#1A3B2B] bg-[#f5f9f3] ring-2 ring-[#1A3B2B]/10' : 'border-[#e5eae5] hover:border-[#b8c9b8]'}`}>
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-[#edf4e9] text-[#315a3b]"><Wallet size={20} /></span>
                <span className="flex-1"><strong className="block text-sm text-[#304137]">E-Wallet</strong><small className="mt-1 block text-xs text-[#8b978e]">Touch ’n Go eWallet</small></span>
                <span className={`h-4 w-4 rounded-full border ${paymentMethod === 'ewallet' ? 'border-[5px] border-[#1A3B2B]' : 'border-[#cbd4cc]'}`} />
              </button>
              {paymentMethod === 'ewallet' && (
                <div className="flex items-center gap-3 rounded-xl border border-[#e5eae5] bg-[#fbfcfb] p-3 sm:ml-[52px]">
                  <span className="grid h-9 w-9 place-items-center rounded-lg bg-[#e8f1ff] text-[#3060a0]"><CreditCard size={17} /></span>
                  <span className="text-sm font-semibold text-[#435349]">Touch ’n Go eWallet</span>
                  <Check size={16} className="ml-auto text-[#4c8051]" />
                </div>
              )}
            </div>
            {paymentNotice && <p role="status" className="mt-4 rounded-xl bg-[#f3f7f1] p-3 text-xs font-medium text-[#4f6b51]">{paymentNotice}</p>}
            <button type="button" onClick={submitDemoPayment} disabled={!paymentMethod || (paymentMethod === 'fpx' && !bank)} className="mt-5 inline-flex h-12 w-full items-center justify-center gap-2 rounded-xl bg-[#1A3B2B] px-5 text-sm font-bold text-white transition hover:bg-[#28543b] disabled:cursor-not-allowed disabled:opacity-45">
              Pay Now <ArrowRight size={16} />
            </button>
            <p className="mt-3 flex items-center justify-center gap-1.5 text-center text-[11px] text-[#929c94]"><ShieldCheck size={13} />Secure payment powered by Billplz.</p>
          </section>
          <button type="button" onClick={() => setStep('review')} className="mx-auto flex items-center gap-2 text-xs font-semibold text-[#6f7d73] hover:text-[#1A3B2B]"><ArrowLeft size={14} /> Back to your booking</button>
        </div>
      )}

      {step === 'selection' && (
        <button type="button" onClick={() => setStep('review')} className="fixed bottom-[78px] left-4 right-4 z-20 mx-auto flex max-w-[740px] items-center justify-between rounded-2xl bg-[#1A3B2B] px-4 py-3 text-left text-white shadow-[0_12px_35px_rgba(20,50,32,0.25)] transition hover:bg-[#28543b] md:bottom-5 min-[801px]:left-[280px] min-[801px]:right-8">
          <span className="flex min-w-0 items-center gap-3">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-white/10"><ReceiptText size={19} /></span>
            <span className="min-w-0"><strong className="block text-sm font-bold">View my order</strong><small className="mt-0.5 block truncate text-xs text-white/70">{cart.length} {cart.length === 1 ? 'item' : 'items'} · {formatMoney(total)}</small></span>
          </span>
          <ArrowRight size={19} className="shrink-0" />
        </button>
      )}
    </div>
  )
}

export function BookingRecords() {
  const [filter, setFilter] = useState('All')
  return (
    <div className="content-page">
      <div className="page-intro records-intro">
        <div><span className="eyebrow">YOUR COURT TIME</span><h1>Booking records</h1><p>All your games, together in one place.</p></div>
        <div className="records-actions"><button className="records-icon-button" aria-label="Search bookings"><Search size={18} /></button><button className="records-icon-button" aria-label="Filter bookings"><Filter size={18} /></button></div>
      </div>
      <div className="records-tabs">{['All', 'Upcoming', 'Past'].map((value) => <button key={value} onClick={() => setFilter(value)} className={filter === value ? 'records-tab records-tab-active' : 'records-tab'}>{value}</button>)}</div>
      <section className="empty-records">
        <span className="empty-records-art"><CalendarDays size={28} /></span>
        <span className="eyebrow">NOTHING ON THE SCOREBOARD</span>
        <h2>No {filter === 'All' ? 'bookings' : filter.toLowerCase() + ' bookings'} yet</h2>
        <p>Your next game is just around the corner. Book a facility to get started.</p>
        <Link className="primary-button" to="/book">Find a facility <ArrowRight size={17} /></Link>
      </section>
    </div>
  )
}
