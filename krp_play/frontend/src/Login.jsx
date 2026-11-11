import { useState } from 'react'
import { ArrowRight, LockKeyhole, Mail, ShieldCheck, Volleyball } from 'lucide-react'
import { Link, useNavigate } from 'react-router-dom'
import AuthField from './AuthField.jsx'
import { useAuth } from './AuthContext.jsx'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [keepSignedIn, setKeepSignedIn] = useState(true)
  const [notice, setNotice] = useState('')
  const { signIn } = useAuth()
  const navigate = useNavigate()

  function handleSubmit(event) {
    event.preventDefault()
    signIn(email)
    navigate('/', { replace: true })
  }

  return (
    <main className="auth-page">
      <div className="auth-layout">
        <section className="auth-story">
          <Link to="/login" className="brand-lockup">
            <span className="brand-mark"><Volleyball size={24} /></span>
            <span>KRP <b>PLAY</b></span>
          </Link>
          <div className="auth-story-copy">
            <span className="eyebrow eyebrow-lime">YOUR CAMPUS. YOUR COURT.</span>
            <h1>Make room<br />for your next<br /><em>great game.</em></h1>
            <p>Find your people, book your court, and get back to the game you love.</p>
          </div>
          <div className="auth-story-foot"><ShieldCheck size={17} /> Made for the KRP community</div>
        </section>

        <section className="auth-panel-wrap">
          <form className="auth-card" onSubmit={handleSubmit}>
            <div className="auth-mobile-brand brand-lockup">
              <span className="brand-mark"><Volleyball size={23} /></span>
              <span>KRP <b>PLAY</b></span>
            </div>
            <span className="eyebrow">WELCOME BACK</span>
            <h2>Ready to play?</h2>
            <p className="auth-subtitle">Sign in to continue.</p>

            {notice && <p className="form-notice" role="status">{notice}</p>}

            <div className="auth-fields">
              <AuthField
                label="Email"
                icon={Mail}
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                placeholder="you@university.edu"
                autoComplete="email"
              />
              <AuthField
                label="Password"
                icon={LockKeyhole}
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Enter your password"
                autoComplete="current-password"
                showPassword={showPassword}
                onTogglePassword={() => setShowPassword((shown) => !shown)}
              />
            </div>
            <div className="auth-options">
              <label className="check-label">
                <input type="checkbox" checked={keepSignedIn} onChange={(event) => setKeepSignedIn(event.target.checked)} />
                <span>Keep me signed in</span>
              </label>
              <button type="button" className="text-link" onClick={() => setNotice('Password reset is not connected in this demo.')}>
                Forgot password?
              </button>
            </div>
            <button type="submit" className="primary-button auth-submit">
              Sign in to KRP Play <ArrowRight size={18} />
            </button>
            <p className="auth-switch">Don’t have an account? <Link to="/signup">Sign up</Link></p>
            <p className="demo-hint">Demo mode · enter any email and password</p>
          </form>
        </section>
      </div>
    </main>
  )
}
