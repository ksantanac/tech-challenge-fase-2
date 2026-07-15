-- Seed exclusivo para ambiente de desenvolvimento local (docker-compose).
-- Chave em texto plano: dev-service-key-local-12345 (usada via SERVICE_API_KEY no evaluation-service)
INSERT INTO api_keys (name, key_hash, is_active)
VALUES ('local-dev-service-key', '34fff5ad07c2febcd96d67958f8a3c78dffe30b3d45d68d423624bd7e5e4a837', true)
ON CONFLICT (key_hash) DO NOTHING;
