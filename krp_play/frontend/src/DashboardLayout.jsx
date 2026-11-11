import { useState } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { CalendarDays, ChevronRight, ClipboardList, Home, Info, LogOut, Menu, UserRound, Volleyball, X } from 'lucide-react'
import { useAuth } from './AuthContext.jsx'

const navItems = [
  { label: 'KRP Sports Complex Info', shortLabel: 'Home', to: '/', icon: Info },
  { label: 'Book a Facility', shortLabel: 'Book', to: '/book', icon: CalendarDays },
  { label: 'Booking Records', shortLabel: 'Records', to: '/records', icon: ClipboardList },
  { label: 'Profile', shortLabel: 'Profile', to: '/profile', icon: UserRound },
]

function initials(name = '') {
  return name.trim().split(/\s+/).slice(0, 2).map((part) => part[0] || '').join('').toUpperCase() || 'KP'
}

function Sidebar({ open, onClose }) {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()

  function logout() {
    signOut()
    navigate('/login', { replace: true })
  }

  return (
    <>
      {open && <button aria-label="Close navigation" className="sidebar-backdrop" onClick={onClose} />}
      <aside className={`sidebar ${open ? 'sidebar-open' : ''}`}>
        <div className="sidebar-brand">
          <span className="brand-mark"><Volleyball size={22} /></span>
          <span>KRP <b>PLAY</b></span>
          <button className="sidebar-close" onClick={onClose} aria-label="Close menu"><X size={20} /></button>
        </div>
        <div className="sidebar-user">
          <span className="avatar">{initials(user?.fullName)}</span>
          <span className="sidebar-user-copy">
            <strong>{user?.fullName}</strong>
            <small>{user?.role || user?.category || 'Student'}</small>
          </span>
          <ChevronRight className="sidebar-user-chevron" size={16} />
        </div>
        <span className="sidebar-caption">MENU</span>
        <nav className="sidebar-nav" aria-label="Main navigation">
          {navItems.map(({ label, to, icon: Icon }) => (
            <NavLink key={to} to={to} end={to === '/'} className={({ isActive }) => `sidebar-link ${isActive ? 'sidebar-link-active' : ''}`} onClick={onClose}>
              <Icon size={19} strokeWidth={1.8} /><span>{label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="sidebar-tip">
            <span className="sidebar-tip-icon"><Volleyball size={17} /></span>
            <strong>Time to play?</strong>
            <p>Find a court and bring your crew together.</p>
            <NavLink to="/book" onClick={onClose}>Explore facilities <ChevronRight size={15} /></NavLink>
          </div>
          <button className="sidebar-logout" onClick={logout}><LogOut size={18} /> Log out</button>
          <span className="sidebar-version">KRP PLAY · YOUR CAMPUS SPORTS HUB</span>
        </div>
      </aside>
    </>
  )
}

function BottomNav() {
  const items = navItems.filter((item) => item.to === '/' || item.to === '/book' || item.to === '/profile')
  return (
    <nav className="bottom-nav" aria-label="Mobile navigation">
      {items.map(({ shortLabel, to, icon: Icon }) => (
        <NavLink key={to} to={to} end={to === '/'} className={({ isActive }) => `bottom-nav-item ${isActive ? 'bottom-nav-active' : ''}`}>
          <span className="bottom-nav-icon"><Icon size={19} strokeWidth={1.9} /></span>
          <span>{shortLabel}</span>
        </NavLink>
      ))}
    </nav>
  )
}

export default function DashboardLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const { user } = useAuth()
  const location = useLocation()
  const title = navItems.find((item) => item.to === location.pathname)?.label ?? 'KRP PLAY'

  return (
    <div className="dashboard-shell">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="dashboard-main">
        <header className="topbar">
          <button className="menu-toggle" onClick={() => setSidebarOpen(true)} aria-label="Open menu"><Menu size={22} /></button>
          <div className="topbar-title"><span className="topbar-kicker">KRP PLAY</span><strong>{title}</strong></div>
          <NavLink to="/profile" className="topbar-profile" aria-label={`Profile for ${user?.fullName}`}>
            <span className="avatar avatar-small">{initials(user?.fullName)}</span>
          </NavLink>
        </header>
        <main className="page-content"><Outlet /></main>
        <BottomNav />
      </div>
    </div>
  )
}
