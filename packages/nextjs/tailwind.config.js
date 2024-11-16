/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
    "./utils/**/*.{js,ts,jsx,tsx}",
  ],
  plugins: [require("daisyui")],
  darkTheme: "dark",
  darkMode: ["class", "[data-theme='dark']"],
  // DaisyUI theme colors
  daisyui: {
    themes: [
      {
        light: {
          primary: "#2F855A", // Darker professional green
          "primary-content": "#ffffff", // White text for contrast
          secondary: "#38B2AC", // Teal for subtle variation
          "secondary-content": "#ffffff",
          accent: "#2C7A7B", // Cohesive accent green
          "accent-content": "#ffffff",
          neutral: "#1F2937", // Dark neutral (dark slate)
          "neutral-content": "#d1fae5", // Light greenish text
          "base-100": "#ffffff", // White background
          "base-200": "#dcfce7", // Light green background instead of blue
          "base-300": "#bbf7d0", // Slightly darker green for depth
          "base-content": "#1F2937", // Dark text for readability
          info: "#2F855A", // Green informational elements
          success: "#38B2AC", // Teal success messages
          warning: "#D69E2E", // Amber warning
          error: "#E53E3E", // Red error messages

          "--rounded-btn": "0.5rem", // Slightly less rounded buttons

          ".tooltip": {
            "--tooltip-tail": "6px",
            "--tooltip-color": "#2F855A", // Green tooltip
          },
          ".link": {
            textUnderlineOffset: "2px",
          },
          ".link:hover": {
            opacity: "80%",
          },
        },
      },
      {
        dark: {
          primary: "#276749", // Deep green for dark theme
          "primary-content": "#d1fae5", // Light greenish text
          secondary: "#319795", // Teal for subtle variation
          "secondary-content": "#d1fae5",
          accent: "#285E61", // Cohesive accent green
          "accent-content": "#d1fae5",
          neutral: "#1A202C", // Very dark neutral
          "neutral-content": "#c6f6d5", // Light greenish text
          "base-100": "#1A202C", // Very dark background
          "base-200": "#22543d", // Dark green background instead of blue
          "base-300": "#2F855A", // Slightly lighter dark green
          "base-content": "#c6f6d5", // Light greenish text
          info: "#2F855A", // Green informational elements
          success: "#38B2AC", // Teal success messages
          warning: "#D69E2E", // Amber warning
          error: "#E53E3E", // Red error messages

          "--rounded-btn": "0.5rem", // Slightly less rounded buttons

          ".tooltip": {
            "--tooltip-tail": "6px",
            "--tooltip-color": "#276749", // Green tooltip
          },
          ".link": {
            textUnderlineOffset: "2px",
          },
          ".link:hover": {
            opacity: "80%",
          },
        },
      },
    ],
  },
  theme: {
    extend: {
      boxShadow: {
        center: "0 0 12px -2px rgb(0 0 0 / 0.05)",
      },
      animation: {
        "pulse-fast": "pulse 1s cubic-bezier(0.4, 0, 0.6, 1) infinite",
      },
      colors: {
        // Ensure no blue colors are present
        transparent: 'transparent',
        current: 'currentColor',
      },
    },
  },
};
