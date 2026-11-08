/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        soil: {
          50: '#FDFCFB',
          100: '#F7F4F0',
          200: '#EFE9E1',
          300: '#DFD5C6',
          400: '#C2B29D',
          500: '#A08D75',
          600: '#7E6D58',
          700: '#5F5140',
          800: '#42382C',
          900: '#2A241C',
        },
        primary: {
          50: '#F2F9F3',
          100: '#E2F2E5',
          500: '#2E7D32',
          600: '#256629',
          700: '#1D5020',
          800: '#153A17',
          900: '#0C220E',
        },
        wheat: {
          50: '#FDFBF2',
          100: '#FBF5E0',
          500: '#D4A017',
          600: '#B8860B',
          700: '#946C09',
        },
        clay: {
          50: '#FDF4F2',
          500: '#C0392B',
          600: '#9E2D21',
        }
      },
    },
  },
  plugins: [],
};

