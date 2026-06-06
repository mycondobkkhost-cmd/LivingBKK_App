/** PROPPITER × Robinhood TH — Tailwind / CSS token reference */
module.exports = {
  theme: {
    extend: {
      colors: {
        proppiter: {
          purple: '#4E2A84',
          'purple-dark': '#3A1F66',
          'purple-mid': '#6B3FA0',
          'purple-light': '#9B6DFF',
          'purple-tint': '#F3E8FF',
          yellow: '#FFCB05',
          orange: '#FF6B00',
          'orange-bright': '#FF8A00',
          navy: '#1A1B41',
          surface: '#FFFFFF',
          background: '#F8F9FA',
          border: '#E8EAEF',
          'text-primary': '#1A1B41',
          'text-secondary': '#6B7280',
          'wordmark-prop': '#4E2A84',
          'wordmark-piter': '#FF6B00',
        },
      },
      backgroundImage: {
        'proppiter-header':
          'linear-gradient(180deg, #4E2A84 0%, #6B3FA0 35%, #FF8A00 68%, #F8F9FA 92%, #FFFFFF 100%)',
        'proppiter-logo':
          'linear-gradient(135deg, #4E2A84 0%, #9B6DFF 40%, #FFCB05 72%, #FF8A00 100%)',
      },
      borderRadius: {
        search: '28px',
        card: '16px',
        pill: '999px',
      },
      boxShadow: {
        search:
          '0 4px 14px rgba(78, 42, 132, 0.12)',
        card: '0 8px 20px rgba(78, 42, 132, 0.08)',
      },
      fontFamily: {
        sans: ['Prompt', 'Noto Sans Thai', 'system-ui', 'sans-serif'],
      },
    },
  },
};
