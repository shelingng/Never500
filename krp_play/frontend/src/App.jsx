import { Navigate, Route, Routes } from 'react-router-dom'
import { useAuth } from './AuthContext.jsx'
import DashboardLayout from './DashboardLayout.jsx'
import Home from './Home.jsx'
import Login from './Login.jsx'
import Profile from './Profile.jsx'
import SignUp from './SignUp.jsx'
import { BookingPage, BookingRecords } from './Bookings.jsx'

function ProtectedLayout() {
  const { user } = useAuth()
  return user ? <DashboardLayout /> : <Navigate to="/login" replace />
}

export default function App() {
  const { user } = useAuth()

  return (
    <Routes>
      <Route path="/login" element={user ? <Navigate to="/" replace /> : <Login />} />
      <Route path="/signup" element={user ? <Navigate to="/" replace /> : <SignUp />} />
      <Route element={<ProtectedLayout />}>
        <Route path="/" element={<Home />} />
        <Route path="/book" element={<BookingPage />} />
        <Route path="/records" element={<BookingRecords />} />
        <Route path="/profile" element={<Profile />} />
      </Route>
      <Route path="*" element={<Navigate to={user ? '/' : '/login'} replace />} />
    </Routes>
  )
}
