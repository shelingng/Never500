import { useState } from 'react'
import { ArrowRight, CalendarDays, Check, Clock3, Dumbbell, Filter, MapPin, Plus, Search, Table2, Volleyball } from 'lucide-react'
import { Link } from 'react-router-dom'

const options = [
  { name: 'Badminton Arena', description: 'Courts 01 & 02 · Synthetic flooring', icon: Volleyball, rate: 'RM 8 / hour', image: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=700&q=80' },
  { name: 'Table Tennis Hall', description: 'Tables 01 & 02 · High-rebound tables', icon: Table2, rate: 'RM 5 / hour', image: 'https://images.unsplash.com/photo-1611251135345-18c56206b863?auto=format&fit=crop&w=700&q=80' },
  { name: 'Fitness Centre & Gym', description: 'Weights, cardio & resistance machines', icon: Dumbbell, rate: 'RM 4 / visit', image: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=700&q=80' },
]

export function BookingPage() {
  const [selected, setSelected] = useState(options[0].name)
  const [date, setDate] = useState('')
  const [time, setTime] = useState('')
  const [confirmation, setConfirmation] = useState('')

  function submitBooking(event) {
    event.preventDefault()
    if (!date || !time) {
      setConfirmation('Choose a date and time to continue.')
      return
    }
    setConfirmation(`Your ${selected} request for ${date} at ${time} is ready. This is a UI demo, so no booking was submitted.`)
  }

  return (
    <div className="content-page">
      <div className="page-intro">
        <span className="eyebrow">MAKE IT A GAME DAY</span>
        <h1>Book a facility</h1>
        <p>Choose your court, pick a time, and bring your crew.</p>
      </div>
      <div className="booking-layout">
        <section className="booking-facilities">
          <div className="section-heading"><div><span className="eyebrow">STEP 1</span><h2>Choose your space</h2></div><span className="step-count">01 <i>/ 02</i></span></div>
          <div className="booking-option-list">
            {options.map(({ name, description, icon: Icon, rate, image }) => (
              <button key={name} onClick={() => setSelected(name)} className={`booking-option ${selected === name ? 'booking-option-selected' : ''}`}>
                <img src={image} alt="" />
                <span className="booking-option-copy"><strong>{name}</strong><small>{description}</small><em>{rate}</em></span>
                <span className="booking-option-icon">{selected === name ? <Check size={17} /> : <Icon size={18} />}</span>
              </button>
            ))}
          </div>
        </section>
        <form className="booking-form-card" onSubmit={submitBooking}>
          <div className="section-heading"><div><span className="eyebrow">STEP 2</span><h2>Pick your time</h2></div><span className="step-count">02 <i>/ 02</i></span></div>
          <label className="form-label">Date<span className="booking-field"><CalendarDays size={18} /><input type="date" value={date} onChange={(event) => setDate(event.target.value)} min={new Date().toISOString().slice(0, 10)} required /></span></label>
          <label className="form-label">Available time<span className="booking-field"><Clock3 size={18} /><select value={time} onChange={(event) => setTime(event.target.value)} required><option value="">Select a time slot</option>{['9:00 AM', '10:00 AM', '11:00 AM', '1:00 PM', '2:00 PM', '3:00 PM', '5:00 PM', '6:00 PM', '7:00 PM', '8:00 PM'].map((slot) => <option key={slot}>{slot}</option>)}</select></span></label>
          <div className="booking-summary"><span><MapPin size={16} /> Selected facility</span><strong>{selected}</strong></div>
          {confirmation && <p className="booking-confirmation" role="status">{confirmation}</p>}
          <button type="submit" className="primary-button booking-submit">Continue <ArrowRight size={17} /></button>
          <small className="booking-note">Booking requests are simulated in this demo.</small>
        </form>
      </div>
      <div className="booking-help"><span className="booking-help-icon"><Plus size={18} /></span><span><strong>Need a hand?</strong><small>Check opening times with the KRP Sports Complex team.</small></span><a href="mailto:krp-sports@utm.my">Contact us <ArrowRight size={14} /></a></div>
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
