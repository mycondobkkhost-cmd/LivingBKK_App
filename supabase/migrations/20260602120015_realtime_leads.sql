-- Enable Realtime for leads (in-app notifications)

ALTER PUBLICATION supabase_realtime ADD TABLE public.leads;
