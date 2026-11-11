import { createContext, useContext, useMemo, useState } from 'react'

const AuthContext = createContext(null)

const displayNameFromEmail = (email) => {
  const name = email.split('@')[0].replace(/[._-]+/g, ' ')
  return name.replace(/\b\w/g, (letter) => letter.toUpperCase()) || 'KRP Player'
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)

  const value = useMemo(
    () => ({
      user,
      signIn(email) {
        const normalizedEmail = email.trim().toLowerCase()
        setUser({
          fullName: displayNameFromEmail(normalizedEmail),
          matricNo: 'A24CS0107',
          category: 'KRP Student',
          phone: '012 345 6789',
          email: normalizedEmail,
          role: 'Student',
        })
      },
      signUp(details) {
        setUser({ ...details, role: 'Student' })
      },
      updateProfile(details) {
        setUser((currentUser) => (currentUser ? { ...currentUser, ...details } : currentUser))
      },
      signOut() {
        setUser(null)
      },
    }),
    [user],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within an AuthProvider')
  return context
}
