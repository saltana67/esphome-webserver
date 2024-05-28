FROM node:21-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
COPY .. /app
WORKDIR /app/captive-portal
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install 
RUN pwd
RUN ls -la
RUN ls -la ..
EXPOSE 8000
CMD [ "npm", "run", "build" ]
