alter table "storage"."files"
  add constraint "files_uploaded_by_user_id_fkey"
  foreign key ("uploaded_by_user_id")
  references "auth"."users"
  ("id") on update no action on delete cascade;
