UPDATE data.rpt_recon_control set status ='COMPLETED' WHERE status ='SUCCESS';
UPDATE data.rpt_recon_control_child set status ='COMPLETED' WHERE status ='SUCCESS';