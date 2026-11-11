import { useState } from 'react'
import { ArrowRight, BadgeCheck, LockKeyhole, Mail, Phone, UserRound, Volleyball } from 'lucide-react'
import { Link, useNavigate } from 'react-router-dom'
import AuthField from './AuthField.jsx'
import { useAuth } from './AuthContext.jsx'

const emptyDetails = {
  fullName: '',
  matricNo: '',
  category: 'KRP Student',
  phone: '',
  email: '',
}

export default function SignUp() {
  const [details, setDetails] = useState(emptyDetails)
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [error, setError] = useState('')
  const { signUp } = useAuth()
  const navigate = useNavigate()

  function update(key, value) {
    setDetails((current) => ({ ...current, [key]: value }))
  }

  function handleSubmit(event) {
    event.preventDefault()
    if (Object.values(details).some((value) => !value.trim()) || !password || !confirmPassword) {
      setError('Please complete all required fields.')
      return
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(details.email.trim())) {
      setError('Please enter a valid email address.')
      return
    }
    if (password.length < 8) {
      setError('Use at least 8 characters for your password.')
      return
    }
    if (password !== confirmPassword) {
      setError('Your passwords don’t match. Please try again.')
      return
    }
    setError('')
    signUp({ ...details, email: details.email.trim().toLowerCase() })
    navigate('/', { replace: true })
  }

  return (
    <main className="auth-page signup-page">
      <div className="auth-layout signup-layout">
        <section className="auth-story">
          <Link to="/login" className="brand-lockup">
            <span className="brand-mark"><Volleyball size={24} /></span>
            <span>KRP <b>PLAY</b></span>
          </Link>
          <div className="auth-story-copy">
            <span className="eyebrow eyebrow-lime">GOOD GAMES START HERE</span>
            <h1>Your next<br />game is just<br /><em>around the corner.</em></h1>
            <p>Join the community and make every break a chance to play.</p>
          </div>
          <div className="auth-story-foot"><BadgeCheck size={17} /> One account. All your KRP bookings.</div>
        </section>

        <section className="auth-panel-wrap signup-panel">
          <form className="auth-card signup-card" onSubmit={handleSubmit} noValidate>
            <div className="auth-mobile-brand brand-lockup">
              <span className="brand-mark"><Volleyball size={23} /></span>
              <span>KRP <b>PLAY</b></span>
            </div>
            <span className="eyebrow">JOIN THE COMMUNITY</span>
            <h2>Create your account</h2>
            <p className="auth-subtitle">A few details and you’re ready to play.</p>
            {error && <p className="form-notice form-error" role="alert">{error}</p>}

            <div className="signup-fields">
              <AuthField label="Full Name" icon={UserRound} value={details.fullName} onChange={(event) => update('fullName', event.target.value)} placeholder="Your full name" autoComplete="name" />
              <AuthField label="Matric No." icon={BadgeCheck} value={details.matricNo} onChange={(event) => update('matricNo', event.target.value)} placeholder="e.g. A24CS0107" />
              <label className="block">
                <span className="mb-2 block text-sm font-semibold text-slate-700">Student Category</span>
                <span className="auth-input-wrap select-wrap">
                  <UserRound size={18} className="shrink-0 text-slate-400" />
                  <select className="auth-input" value={details.category} onChange={(event) => update('category', event.target.value)}>
                    <option>KRP Student</option>
                    <option>Non-KRP Student</option>
                  </select>
                </span>
              </label>
              <AuthField label="Phone No." icon={Phone} type="tel" value={details.phone} onChange={(event) => update('phone', event.target.value)} placeholder="+60 12 345 6789" autoComplete="tel" />
              <AuthField label="Email" icon={Mail} type="email" value={details.email} onChange={(event) => update('email', event.target.value)} placeholder="you@university.edu" autoComplete="email" />
              <AuthField label="Password" icon={LockKeyhole} type="password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="At least 8 characters" autoComplete="new-password" minLength={8} showPassword={showPassword} onTogglePassword={() => setShowPassword((shown) => !shown)} />
              <AuthField label="Confirm Password" icon={LockKeyhole} type="password" value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} placeholder="Re-enter your password" autoComplete="new-password" minLength={8} showPassword={showConfirmPassword} onTogglePassword={() => setShowConfirmPassword((shown) => !shown)} />
            </div>
            <button type="submit" className="primary-button auth-submit signup-submit">
              Sign Up <ArrowRight size={18} />
            </button>
            <p className="auth-switch">Already have an account? <Link to="/login">Log in</Link></p>
          </form>
        </section>
      </div>
    </main>
  )
}
