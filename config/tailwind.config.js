module.exports = {
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#fafafa",
          100: "#f4f4f5",
          200: "#e4e4e7",
          300: "#d4d4d8",
          400: "#a1a1aa",
          500: "#71717a",
          600: "#52525b",
          700: "#3f3f46",
          800: "#27272a",
          900: "#18181b",
          950: "#09090b",
        },
        accent: {
          DEFAULT: "#c2410c",
          light: "#fb923c",
          dark: "#7c2d12",
        },
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        serif: ["Lora", "Georgia", "serif"],
        mono: ["JetBrains Mono", "monospace"],
      },
      maxWidth: {
        prose: "65ch",
        container: "1200px",
      },
      typography: ({ theme }) => ({
        DEFAULT: {
          css: {
            "--tw-prose-body": theme("colors.gray.700"),
            "--tw-prose-headings": theme("colors.gray.900"),
            "--tw-prose-links": theme("colors.accent.DEFAULT"),
            "--tw-prose-bold": theme("colors.gray.900"),
            "--tw-prose-quotes": theme("colors.gray.800"),
            "--tw-prose-quote-borders": theme("colors.brand.300"),
            "--tw-prose-code": theme("colors.brand.900"),
            a: {
              textDecoration: "none",
              borderBottom: `1px solid ${theme("colors.accent.light")}`,
              "&:hover": { borderBottomWidth: "2px" },
            },
          },
        },
      }),
    },
  },
  plugins: [require("@tailwindcss/typography")],
};
