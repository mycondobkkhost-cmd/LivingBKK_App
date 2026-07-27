-- Narrow chat thread unique indexes so staff/demand/requirement and
-- discovery/unresolved-listing threads do not collide.

-- Was: one staff_support room_kind per user (blocked demand_offer +
-- customer_requirement which also use room_kind = staff_support).
DROP INDEX IF EXISTS public.chat_threads_user_staff_support_uidx;
CREATE UNIQUE INDEX chat_threads_user_staff_support_uidx
  ON public.chat_threads (user_id)
  WHERE room_kind = 'staff_support'
    AND category = 'staff_support';

-- Was: one property thread with listing_id IS NULL per user (blocked
-- unresolved listing-code chats after DISCOVERY existed).
DROP INDEX IF EXISTS public.chat_threads_user_discovery_uidx;
CREATE UNIQUE INDEX chat_threads_user_discovery_uidx
  ON public.chat_threads (user_id)
  WHERE room_kind = 'property'
    AND listing_id IS NULL
    AND category = 'discovery';

-- One unresolved listing-code property thread per user+code.
CREATE UNIQUE INDEX IF NOT EXISTS chat_threads_user_property_unresolved_code_uidx
  ON public.chat_threads (user_id, listing_code)
  WHERE room_kind = 'property'
    AND listing_id IS NULL
    AND listing_code IS NOT NULL
    AND category <> 'discovery';
