import { useState } from 'react'
import { ArrowRight, Clock3, MapPin, Navigation, Sparkles, Volleyball } from 'lucide-react'
import { Link } from 'react-router-dom'

const facilities = [
  {
    name: 'Badminton Arena',
    detail: 'Tournament-grade courts',
    image: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=800&q=85',
  },
  {
    name: 'Fitness Centre',
    detail: 'Train at your own pace',
    image: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=800&q=85',
  },
  {
    name: 'Table Tennis Hall',
    detail: 'Fast games, good company',
    image: 'https://images.unsplash.com/photo-1611251135345-18c56206b863?auto=format&fit=crop&w=800&q=85',
  },
]

export default function Home() {
  const [activeFacility, setActiveFacility] = useState(0)

  return (
    <div className="home-page">
      <section className="welcome-row">
        <div>
          <span className="eyebrow">WELCOME TO YOUR SPORTS HUB</span>
          <h1>Good to see you.<br /><span>Ready to play?</span></h1>
          <p>Make today a little more active at KRP Sports Complex.</p>
        </div>
        <span className="welcome-sparkle"><Sparkles size={23} /></span>
      </section>

      <section className="complex-hero">
        <div className="complex-hero-image" role="img" aria-label="Sports court at KRP Sports Complex" />
        <div className="complex-hero-shade" />
        <div className="complex-hero-content">
          <span className="hero-pill"><span /> YOUR CAMPUS SPORTS HUB</span>
          <h2>KRP Sports<br />Complex</h2>
          <p>Move more. Play together. Make it count.</p>
          <a className="hero-map-link" href="https://maps.google.com/?q=Kolej+Rahman+Putra+UTM+Skudai" target="_blank" rel="noreferrer">
            <MapPin size={16} /> Open Maps <ArrowRight size={15} />
          </a>
        </div>
        <span className="hero-vertical-label">KOLEJ RAHMAN PUTRA · UTM</span>
      </section>

      <section className="info-strip">
        <div className="info-strip-item"><span className="info-icon"><MapPin size={18} /></span><span><small>FIND US</small><strong>Kolej Rahman Putra, UTM Skudai</strong></span></div>
        <div className="info-strip-item"><span className="info-icon"><Clock3 size={18} /></span><span><small>OPENING HOURS</small><strong>Daily · 8:00 AM – 11:00 PM</strong></span></div>
      </section>

      <section className="discover-section">
        <div className="section-heading">
          <div><span className="eyebrow">FIND YOUR GAME</span><h2>There’s a place for you.</h2></div>
          <Link to="/book" className="subtle-link">All facilities <ArrowRight size={15} /></Link>
        </div>
        <div className="facility-cards">
          {facilities.map((facility, index) => (
            <button key={facility.name} className={`facility-preview ${activeFacility === index ? 'facility-preview-active' : ''}`} onClick={() => setActiveFacility(index)}>
              <img src={facility.image} alt="" />
              <span className="facility-preview-shade" />
              <span className="facility-preview-info"><strong>{facility.name}</strong><small>{facility.detail}</small></span>
              <span className="facility-preview-arrow"><ArrowRight size={16} /></span>
            </button>
          ))}
        </div>
      </section>

      <aside className="home-cta">
        <div className="home-cta-icon"><Volleyball size={22} /></div>
        <div><strong>Your next game is waiting.</strong><p>Pick a facility and get your plans in motion.</p></div>
        <Link to="/book" className="primary-button cta-button">Book Now <ArrowRight size={17} /></Link>
      </aside>
      <div className="sticky-book"><Link to="/book" className="primary-button">Book Now <ArrowRight size={17} /></Link></div>
    </div>
  )
}
