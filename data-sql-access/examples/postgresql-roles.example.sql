-- Blueprint data-sql-access: EXAMPLE, not a running configuration.
-- Group roles of one database and the service account of OpenBao.
-- Fictional names under mess.systems; role forms follow the naming standard
-- (04-identity-conventions.md, "Database roles"). PostgreSQL 16 or later.
-- Applied by the Ansible role of the cluster, not by hand.

-- Group roles: no login, granted to temporary users.
CREATE ROLE eng_sdlc_git_owner NOLOGIN;
CREATE ROLE eng_sdlc_git_ro    NOLOGIN;
CREATE ROLE eng_sdlc_git_rw    NOLOGIN;   -- exists, but OpenBao has no role for it: write is off

ALTER DATABASE eng_sdlc_git_prd OWNER TO eng_sdlc_git_owner;
REVOKE ALL ON DATABASE eng_sdlc_git_prd FROM PUBLIC;
GRANT CONNECT ON DATABASE eng_sdlc_git_prd TO eng_sdlc_git_ro, eng_sdlc_git_rw;

\connect eng_sdlc_git_prd
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Read: SELECT only, on named schemas, also for future tables of the owner.
GRANT USAGE  ON SCHEMA public TO eng_sdlc_git_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO eng_sdlc_git_ro;
ALTER DEFAULT PRIVILEGES FOR ROLE eng_sdlc_git_owner IN SCHEMA public
  GRANT SELECT ON TABLES TO eng_sdlc_git_ro;

-- Service account of OpenBao: can create and drop users and grant the group
-- role, but cannot act with it (INHERIT FALSE, SET FALSE) and owns nothing.
-- The password is set once, then replaced by rotate-root.
CREATE ROLE svc_shared_iam_openbao
  LOGIN CREATEROLE NOSUPERUSER NOCREATEDB NOREPLICATION NOBYPASSRLS;
GRANT eng_sdlc_git_ro TO svc_shared_iam_openbao WITH ADMIN TRUE, INHERIT FALSE, SET FALSE;
GRANT pg_signal_backend TO svc_shared_iam_openbao;
