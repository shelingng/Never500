import { Eye, EyeOff } from 'lucide-react'

export default function AuthField({
  label,
  icon: Icon,
  type = 'text',
  value,
  onChange,
  placeholder,
  required = true,
  autoComplete,
  showPassword,
  onTogglePassword,
  minLength,
}) {
  const isPassword = type === 'password'

  return (
    <label className="block">
      <span className="mb-2 block text-sm font-semibold text-slate-700">{label}</span>
      <span className="auth-input-wrap">
        <Icon size={18} strokeWidth={1.8} className="shrink-0 text-slate-400" />
        <input
          className="auth-input"
          type={isPassword && showPassword ? 'text' : type}
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          required={required}
          autoComplete={autoComplete}
          minLength={minLength}
        />
        {isPassword && (
          <button
            type="button"
            className="password-toggle"
            onClick={onTogglePassword}
            aria-label={showPassword ? 'Hide password' : 'Show password'}
          >
            {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
          </button>
        )}
      </span>
    </label>
  )
}
