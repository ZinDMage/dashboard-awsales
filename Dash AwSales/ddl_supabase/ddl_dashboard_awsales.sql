-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.app_config (
  id bigint NOT NULL DEFAULT nextval('app_config_id_seq'::regclass),
  key text NOT NULL UNIQUE,
  value text,
  description text,
  is_secret boolean NOT NULL DEFAULT false,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT app_config_pkey PRIMARY KEY (id)
);
CREATE TABLE public.calendly_events (
  id bigint NOT NULL DEFAULT nextval('calendly_events_id_seq'::regclass),
  invitee_uuid text NOT NULL UNIQUE,
  event_uuid text NOT NULL,
  event_type_uuid text,
  webhook_event text NOT NULL,
  event_name text,
  event_status text NOT NULL DEFAULT 'active'::text,
  host_name text,
  host_email text,
  invitee_name text,
  invitee_email text,
  invitee_phone text,
  invitee_timezone text,
  start_time timestamp with time zone,
  end_time timestamp with time zone,
  rescheduled boolean NOT NULL DEFAULT false,
  canceled_by text,
  canceler_type text,
  cancellation_reason text,
  canceled_at timestamp with time zone,
  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_content text,
  utm_term text,
  yayforms_response_id uuid,
  crm_deal_id integer,
  raw_payload jsonb,
  invitee_created_at timestamp with time zone,
  invitee_updated_at timestamp with time zone,
  webhook_received_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT calendly_events_pkey PRIMARY KEY (id),
  CONSTRAINT calendly_events_yayforms_response_id_fkey FOREIGN KEY (yayforms_response_id) REFERENCES public.yayforms_responses(id),
  CONSTRAINT calendly_events_crm_deal_id_fkey FOREIGN KEY (crm_deal_id) REFERENCES public.crm_deals(deal_id)
);
CREATE TABLE public.crm_deal_activities (
  id bigint NOT NULL DEFAULT nextval('crm_deal_activities_id_seq'::regclass),
  activity_id integer NOT NULL UNIQUE,
  deal_id integer NOT NULL,
  deal_title text,
  activity_type text NOT NULL,
  activity_type_name text,
  subject text,
  note_html text,
  note_clean text,
  public_description text,
  due_date date,
  due_time time without time zone,
  duration text,
  busy_flag boolean DEFAULT false,
  done boolean NOT NULL DEFAULT false,
  marked_as_done_time timestamp with time zone,
  active_flag boolean DEFAULT true,
  user_id integer,
  owner_name text,
  assigned_to_user_id integer,
  created_by_user_id integer,
  update_user_id integer,
  person_id integer,
  person_name text,
  org_id integer,
  org_name text,
  activity_created_at timestamp with time zone,
  activity_updated_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT crm_deal_activities_pkey PRIMARY KEY (id)
);
CREATE TABLE public.crm_deal_fields (
  key text NOT NULL,
  name text NOT NULL,
  field_type text NOT NULL,
  options jsonb,
  edit_flag boolean DEFAULT true,
  synced_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT crm_deal_fields_pkey PRIMARY KEY (key)
);
CREATE TABLE public.crm_deals (
  id bigint NOT NULL DEFAULT nextval('crm_deals_id_seq'::regclass),
  deal_id integer NOT NULL UNIQUE,
  person_id integer,
  person_name text,
  org_id integer,
  org_name text,
  pipeline_id integer NOT NULL,
  pipeline_name text,
  stage_id integer NOT NULL,
  stage_name text,
  stage_order integer,
  funnel_type text,
  title text,
  value numeric DEFAULT 0,
  currency text DEFAULT 'BRL'::text,
  status text NOT NULL DEFAULT 'open'::text,
  probability integer,
  label_ids jsonb,
  owner_id integer,
  owner_name text,
  creator_user_id integer,
  origin text,
  expected_close_date date,
  close_time timestamp with time zone,
  lost_time timestamp with time zone,
  won_time timestamp with time zone,
  first_won_time timestamp with time zone,
  stage_change_time timestamp with time zone,
  is_archived boolean DEFAULT false,
  archive_time timestamp with time zone,
  lost_reason text,
  yayforms_response_id uuid,
  custom_fields jsonb,
  webhook_action text,
  webhook_change_source text,
  previous_data jsonb,
  deal_created_at timestamp with time zone,
  deal_updated_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  person_email text,
  person_phone text,
  CONSTRAINT crm_deals_pkey PRIMARY KEY (id),
  CONSTRAINT crm_deals_yayforms_response_id_fkey FOREIGN KEY (yayforms_response_id) REFERENCES public.yayforms_responses(id)
);
CREATE TABLE public.crm_pipelines (
  id integer NOT NULL,
  name text NOT NULL,
  active boolean DEFAULT true,
  order_nr integer,
  synced_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT crm_pipelines_pkey PRIMARY KEY (id)
);
CREATE TABLE public.crm_stage_transitions (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  deal_id integer NOT NULL,
  deal_title text,
  pipeline_id integer NOT NULL,
  pipeline_name text,
  funnel_type text,
  from_stage_id integer,
  from_stage_name text,
  from_stage_order integer,
  to_stage_id integer NOT NULL,
  to_stage_name text,
  to_stage_order integer,
  direction text DEFAULT 
CASE
    WHEN (from_stage_order IS NULL) THEN 'entry'::text
    WHEN (to_stage_order > from_stage_order) THEN 'forward'::text
    WHEN (to_stage_order < from_stage_order) THEN 'backward'::text
    ELSE 'lateral'::text
END,
  transitioned_at timestamp with time zone NOT NULL,
  time_in_previous_stage_sec numeric,
  owner_id integer,
  owner_name text,
  deal_value numeric,
  deal_status text,
  webhook_action text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT crm_stage_transitions_pkey PRIMARY KEY (id),
  CONSTRAINT fk_stage_transitions_deal FOREIGN KEY (deal_id) REFERENCES public.crm_deals(deal_id)
);
CREATE TABLE public.crm_stages (
  id integer NOT NULL,
  pipeline_id integer NOT NULL,
  name text NOT NULL,
  order_flag integer,
  active_flag boolean DEFAULT true,
  synced_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT crm_stages_pkey PRIMARY KEY (id),
  CONSTRAINT pipedrive_stages_pipeline_id_fkey FOREIGN KEY (pipeline_id) REFERENCES public.crm_pipelines(id)
);
CREATE TABLE public.crm_users (
  id integer NOT NULL,
  name text NOT NULL,
  email text,
  active boolean DEFAULT true,
  role_id integer,
  synced_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT crm_users_pkey PRIMARY KEY (id)
);
CREATE TABLE public.google_ads_costs (
  id bigint NOT NULL DEFAULT nextval('google_ads_costs_id_seq'::regclass),
  campaign_id text NOT NULL,
  campaign_name text NOT NULL,
  campaign_status text,
  ad_group_id text NOT NULL,
  ad_group_name text NOT NULL,
  date date NOT NULL,
  device text NOT NULL,
  impressions integer NOT NULL DEFAULT 0,
  clicks integer NOT NULL DEFAULT 0,
  spend numeric NOT NULL DEFAULT 0,
  average_cpc numeric DEFAULT 0,
  conversions numeric NOT NULL DEFAULT 0,
  all_conversions numeric NOT NULL DEFAULT 0,
  conversions_value numeric NOT NULL DEFAULT 0,
  ctr numeric DEFAULT 
CASE
    WHEN (impressions > 0) THEN round((((clicks)::numeric / (impressions)::numeric) * (100)::numeric), 4)
    ELSE (0)::numeric
END,
  cpm numeric DEFAULT 
CASE
    WHEN (impressions > 0) THEN round(((spend / (impressions)::numeric) * (1000)::numeric), 4)
    ELSE (0)::numeric
END,
  cost_per_conversion numeric DEFAULT 
CASE
    WHEN (conversions > (0)::numeric) THEN round((spend / conversions), 4)
    ELSE (0)::numeric
END,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT google_ads_costs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.linkedin_ads_costs (
  id bigint NOT NULL DEFAULT nextval('linkedin_ads_costs_id_seq'::regclass),
  creative_urn text NOT NULL,
  creative_id text,
  date date NOT NULL,
  impressions integer NOT NULL DEFAULT 0,
  clicks integer NOT NULL DEFAULT 0,
  spend numeric NOT NULL DEFAULT 0,
  leads integer NOT NULL DEFAULT 0,
  video_views integer NOT NULL DEFAULT 0,
  external_conversions integer NOT NULL DEFAULT 0,
  unique_impressions integer NOT NULL DEFAULT 0,
  ctr numeric DEFAULT 
CASE
    WHEN (impressions > 0) THEN round((((clicks)::numeric / (impressions)::numeric) * (100)::numeric), 4)
    ELSE (0)::numeric
END,
  cpc numeric DEFAULT 
CASE
    WHEN (clicks > 0) THEN round((spend / (clicks)::numeric), 4)
    ELSE (0)::numeric
END,
  cpm numeric DEFAULT 
CASE
    WHEN (impressions > 0) THEN round(((spend / (impressions)::numeric) * (1000)::numeric), 4)
    ELSE (0)::numeric
END,
  cpl numeric DEFAULT 
CASE
    WHEN (leads > 0) THEN round((spend / (leads)::numeric), 4)
    ELSE (0)::numeric
END,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT linkedin_ads_costs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.meta_ads_actions (
  id bigint NOT NULL DEFAULT nextval('meta_ads_actions_id_seq'::regclass),
  meta_ads_cost_id bigint NOT NULL,
  ad_id text NOT NULL,
  date_start date NOT NULL,
  date_stop date NOT NULL,
  action_type text NOT NULL,
  value integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  campaign_id text NOT NULL,
  adset_id text NOT NULL,
  CONSTRAINT meta_ads_actions_pkey PRIMARY KEY (id),
  CONSTRAINT meta_ads_actions_meta_ads_cost_id_fkey FOREIGN KEY (meta_ads_cost_id) REFERENCES public.meta_ads_costs(id)
);
CREATE TABLE public.meta_ads_costs (
  id bigint NOT NULL DEFAULT nextval('meta_ads_costs_id_seq'::regclass),
  ad_id text NOT NULL,
  campaign_name text NOT NULL,
  adset_name text NOT NULL,
  ad_name text NOT NULL,
  date_start date NOT NULL,
  date_stop date NOT NULL,
  impressions integer NOT NULL DEFAULT 0,
  clicks integer NOT NULL DEFAULT 0,
  spend numeric NOT NULL DEFAULT 0,
  ctr numeric DEFAULT 
CASE
    WHEN (impressions > 0) THEN round((((clicks)::numeric / (impressions)::numeric) * (100)::numeric), 4)
    ELSE (0)::numeric
END,
  cpc numeric DEFAULT 
CASE
    WHEN (clicks > 0) THEN round((spend / (clicks)::numeric), 4)
    ELSE (0)::numeric
END,
  cpm numeric DEFAULT 
CASE
    WHEN (impressions > 0) THEN round(((spend / (impressions)::numeric) * (1000)::numeric), 4)
    ELSE (0)::numeric
END,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  campaign_id text NOT NULL,
  adset_id text NOT NULL,
  CONSTRAINT meta_ads_costs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.sales (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  email_stripe text,
  email_pipedrive text,
  nome text NOT NULL,
  gerente_responsavel text,
  data_fechamento date,
  mes text,
  plano text NOT NULL,
  fonte text,
  vendedor text,
  afiliado text,
  segmento text,
  isencao_1_mes boolean DEFAULT false,
  receita_plano numeric DEFAULT 0,
  implantacao numeric DEFAULT 0,
  receita_gerada numeric DEFAULT 0,
  status text,
  data_prevista text,
  obs text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT sales_pkey PRIMARY KEY (id)
);
CREATE TABLE public.sync_control (
  id bigint NOT NULL DEFAULT nextval('sync_control_id_seq'::regclass),
  flow_name text NOT NULL,
  source text NOT NULL,
  date_from date,
  date_to date,
  cursor_after text,
  page_number integer DEFAULT 1,
  total_records integer DEFAULT 0,
  status text NOT NULL DEFAULT 'running'::text,
  records_inserted integer DEFAULT 0,
  records_updated integer DEFAULT 0,
  records_skipped integer DEFAULT 0,
  error_message text,
  started_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  completed_at timestamp with time zone,
  CONSTRAINT sync_control_pkey PRIMARY KEY (id)
);
CREATE TABLE public.yayforms_responses (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  external_id text NOT NULL UNIQUE,
  form_id text NOT NULL,
  lead_name text,
  lead_email text,
  lead_phone text,
  lead_project_url text,
  lead_market text,
  lead_segment text,
  lead_revenue_range text,
  lead_monthly_volume text,
  score integer DEFAULT 0,
  variable_2 integer DEFAULT 0,
  variable_3 integer DEFAULT 0,
  ai_feedback jsonb,
  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_content text,
  utm_term text,
  fbc text,
  fbp text,
  ga_client_id text,
  ga_session text,
  gcl_au text,
  ttcsid text,
  ttp text,
  clck text,
  clsk text,
  geo_country_code character varying,
  geo_country_name text,
  geo_region character varying,
  geo_state text,
  geo_city text,
  geo_zipcode character varying,
  geo_latitude numeric,
  geo_longitude numeric,
  geo_timezone text,
  device_type text,
  operating_system text,
  os_version text,
  browser text,
  browser_version text,
  user_agent text,
  ip_address text,
  referrer_url text,
  started_at timestamp with time zone,
  submitted_at timestamp with time zone,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  time_to_complete_sec numeric,
  raw_payload jsonb,
  raw_tracking jsonb,
  ingested_at timestamp with time zone DEFAULT now(),
  CONSTRAINT yayforms_responses_pkey PRIMARY KEY (id)
);