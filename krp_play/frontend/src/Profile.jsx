import { useEffect, useState } from 'react'
import { ArrowRight, BadgeCheck, Check, Mail, Phone, UserRound, X } from 'lucide-react'
import { useAuth } from './AuthContext.jsx'

const fields = [
  { key: 'fullName', label: 'Full Name', icon: UserRound, type: 'text' },
  { key: 'matricNo', label: 'Matric No.', icon: BadgeCheck, type: 'text' },
  { key: 'category', label: 'Student Category', icon: BadgeCheck, type: 'text' },
  { key: 'phone', label: 'Phone No.', icon: Phone, type: 'tel' },
  { key: 'email', label: 'Email Address', icon: Mail, type: 'email' },
]

function initials(name = '') {
  return name.trim().split(/\s+/).slice(0, 2).map((part) => part[0] || '').join('').toUpperCase() || 'KP'
}

export default function Profile() {
  const { user, updateProfile } = useAuth()
  const [editing, setEditing] = useState(false)
  const [details, setDetails] = useState(user)

  useEffect(() => setDetails(user), [user])

  function save(event) {
    event.preventDefault()
    updateProfile(details)
    setEditing(false)
  }

  function cancel() {
    setDetails(user)
    setEditing(false)
  }

  return (
    <div className="content-page profile-page">
      <div className="page-intro">
        <span className="eyebrow">YOUR ACCOUNT</span>
        <h1>Profile</h1>
        <p>Your details, whenever you need them.</p>
      </div>
      <div className="profile-layout">
        <section className="profile-card">
          <div className="profile-card-top">
            <div className="profile-avatar">{initials(user?.fullName)}</div>
            <span className="profile-role"><span /> {user?.role || 'Student'}</span>
            <h2>{user?.fullName}</h2>
            <p>{user?.email}</p>
          </div>
          <div className="profile-card-foot"><span className="profile-foot-mark"><UserRound size={17} /></span><span><strong>KRP PLAY member</strong><small>Ready for your next game</small></span></div>
        </section>
        <form className="profile-details-card" onSubmit={save}>
          <div className="profile-details-heading"><div><span className="eyebrow">PERSONAL DETAILS</span><h2>Your information</h2></div>
            {!editing ? <button type="button" className="outline-button" onClick={() => setEditing(true)}>Edit Profile <ArrowRight size={15} /></button> : <div className="edit-actions"><button type="button" className="cancel-edit" onClick={cancel} aria-label="Cancel edits"><X size={18} /></button><button type="submit" className="save-button"><Check size={16} /> Save</button></div>}
          </div>
          <div className="profile-fields">
            {fields.map(({ key, label, icon: Icon, type }) => (
              <label className="profile-field" key={key}>
                <span className="profile-field-icon"><Icon size={17} /></span>
                <span className="profile-field-content"><small>{label}</small><input type={type} value={details?.[key] || ''} onChange={(event) => setDetails((current) => ({ ...current, [key]: event.target.value }))} readOnly={!editing} required /></span>
                {editing && <span className="profile-edit-indicator">EDITABLE</span>}
              </label>
            ))}
          </div>
          {editing && <p className="profile-edit-note">Changes are stored only for this demo session.</p>}
        </form>
      </div>
    </div>
  )
}
