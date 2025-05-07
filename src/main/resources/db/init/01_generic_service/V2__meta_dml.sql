
-- Status metadata queries

-- Insert DRAFT status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('DRAFT', 'Draft', 'Initial editable state',
   '{"color": "#cccccc", "is_terminal": false, "tooltip": "Can be edited by user"}');

-- Insert PROCESSING status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('PROCESSING', 'Processing', 'Workflow is being processed',
   '{"color": "#ffcc00", "is_terminal": false, "tooltip": "Workflow is in progress"}');


-- Insert PENDING_APPROVAL status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('PENDING_APPROVAL', 'Pending Approval', 'Workflow is awaiting approval',
   '{"color": "#ff6600", "is_terminal": false, "tooltip": "Awaiting approval from the approver"}');

-- Insert APPROVED status (End state)
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('APPROVED', 'Approved', 'Workflow has been approved',
   '{"color": "#33cc33", "is_terminal": true, "tooltip": "Workflow has been successfully approved"}');

-- Insert REJECTED status (End state)
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('REJECTED', 'Rejected', 'Workflow has been rejected',
   '{"color": "#cc3333", "is_terminal": true, "tooltip": "Workflow has been rejected"}');

-- Insert DISCARD status (End state)
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('DISCARD', 'Discarded', 'Workflow has been discarded',
   '{"color": "#666666", "is_terminal": true, "tooltip": "Workflow has been discarded"}');

-- Insert SUCCESS status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('SUCCESS', 'Success', 'Successful',
   '{"color": "#33cc33", "is_terminal": true, "tooltip": "Successful"}');

-- Insert FAILED status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('FAILED', 'Failed', 'Failed',
   '{"color": "#cc3333", "is_terminal": true, "tooltip": "Failed"}');

-- Insert WARNING status
INSERT INTO meta.status_master (code, label, description, properties)
VALUES
  ('WARNING', 'Warning', 'Warnings',
   '{"color": "#cc3333", "is_terminal": true, "tooltip": "Warnings"}');


