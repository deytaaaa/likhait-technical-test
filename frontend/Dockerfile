# Debian rather than Alpine: on musl, npm silently skipped rollup's optional
# platform binary (@rollup/rollup-linux-x64-musl), so `npm run dev` crashed with
# MODULE_NOT_FOUND before Vite ever started. Node 20 matches the CI workflow.
FROM node:20-bookworm-slim

WORKDIR /app

# Copy package files
COPY package*.json ./

# `npm ci` installs exactly what package-lock.json pins, including the optional
# platform binaries `npm install` was dropping.
RUN npm ci

# Copy the rest of the application
COPY . .

# Expose port
EXPOSE 5173

# Start the development server
CMD ["npm", "run", "dev", "--", "--host"]
