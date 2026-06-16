FROM node:20-alpine

WORKDIR /app

# Instala dependencias primero (mejor caché)
COPY package.json ./
RUN npm install --omit=dev

# Copia el resto de la app
COPY . .

ENV PORT=4000
EXPOSE 4000

CMD ["node", "server.js"]
