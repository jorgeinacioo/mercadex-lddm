ALTER TABLE "User" RENAME COLUMN "email" TO "username";
ALTER INDEX "User_email_key" RENAME TO "User_username_key";
UPDATE "User" SET "username" = 'admin' WHERE "username" = 'admin@mercadex.local';
