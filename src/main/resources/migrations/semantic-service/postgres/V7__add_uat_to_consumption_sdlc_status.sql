-- ConsumptionServiceImpl.SDLC_SEQUENCE has always required DRAFT -> DEV -> QA -> UAT -> PROD,
-- but ck_co_sdlc (V3) only ever allowed DEV/QA/PROD, so promoting any exposure to UAT
-- violates the CHECK constraint. Widen it to match the application's real sequence.
ALTER TABLE meta.consumption_outbound DROP CONSTRAINT ck_co_sdlc;
ALTER TABLE meta.consumption_outbound ADD CONSTRAINT ck_co_sdlc CHECK (sdlc_status_cd IN ('DEV', 'QA', 'UAT', 'PROD'));
