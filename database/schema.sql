--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 17.4

-- Started on 2025-07-10 23:11:05

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 216 (class 1259 OID 18722)
-- Name: app_user; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.app_user (
    id integer NOT NULL,
    email character varying(255),
    phone character varying(20),
    display_name character varying(100),
    password_hash character varying(255),
    is_anonymous boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    last_active_at timestamp with time zone DEFAULT now(),
    default_tip_percentage numeric(5,2) DEFAULT 15.00,
    notifications_enabled boolean DEFAULT true
);


ALTER TABLE public.app_user OWNER TO splitdine_prod_user;

--
-- TOC entry 215 (class 1259 OID 18721)
-- Name: app_user_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.app_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_user_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3503 (class 0 OID 0)
-- Dependencies: 215
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- TOC entry 226 (class 1259 OID 18789)
-- Name: final_splits; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.final_splits (
    id integer NOT NULL,
    session_id integer,
    user_id integer,
    subtotal_amount numeric(10,2) DEFAULT 0.00,
    tax_share numeric(10,2) DEFAULT 0.00,
    tip_share numeric(10,2) DEFAULT 0.00,
    service_charge_share numeric(10,2) DEFAULT 0.00,
    total_amount numeric(10,2) DEFAULT 0.00,
    confirmed boolean DEFAULT false,
    paid boolean DEFAULT false,
    payment_method character varying(50),
    payment_reference character varying(255),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.final_splits OWNER TO splitdine_prod_user;

--
-- TOC entry 225 (class 1259 OID 18788)
-- Name: final_splits_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.final_splits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.final_splits_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3504 (class 0 OID 0)
-- Dependencies: 225
-- Name: final_splits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.final_splits_id_seq OWNED BY public.final_splits.id;


--
-- TOC entry 224 (class 1259 OID 18779)
-- Name: item_assignments; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.item_assignments (
    id integer NOT NULL,
    session_id integer,
    item_id integer,
    user_id integer,
    split_type character varying(20) DEFAULT 'equal'::character varying,
    custom_amount numeric(10,2),
    percentage_share numeric(5,2),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.item_assignments OWNER TO splitdine_prod_user;

--
-- TOC entry 223 (class 1259 OID 18778)
-- Name: item_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.item_assignments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_assignments_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3505 (class 0 OID 0)
-- Dependencies: 223
-- Name: item_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.item_assignments_id_seq OWNED BY public.item_assignments.id;


--
-- TOC entry 222 (class 1259 OID 18763)
-- Name: receipt_items; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.receipt_items (
    id integer NOT NULL,
    session_id integer,
    name character varying(255),
    price numeric(10,2),
    quantity integer DEFAULT 1,
    category character varying(20) DEFAULT 'food'::character varying,
    description text,
    parsed_confidence numeric(3,2) DEFAULT 0.00,
    manually_edited boolean DEFAULT false,
    is_shared boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.receipt_items OWNER TO splitdine_prod_user;

--
-- TOC entry 221 (class 1259 OID 18762)
-- Name: receipt_items_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.receipt_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.receipt_items_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3506 (class 0 OID 0)
-- Dependencies: 221
-- Name: receipt_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.receipt_items_id_seq OWNED BY public.receipt_items.id;


--
-- TOC entry 228 (class 1259 OID 18805)
-- Name: session_activity_log; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.session_activity_log (
    id integer NOT NULL,
    session_id integer,
    user_id integer,
    action_type character varying(50),
    action_details jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.session_activity_log OWNER TO splitdine_prod_user;

--
-- TOC entry 227 (class 1259 OID 18804)
-- Name: session_activity_log_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.session_activity_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.session_activity_log_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3507 (class 0 OID 0)
-- Dependencies: 227
-- Name: session_activity_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.session_activity_log_id_seq OWNED BY public.session_activity_log.id;


--
-- TOC entry 220 (class 1259 OID 18753)
-- Name: session_guests; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.session_guests (
    id integer NOT NULL,
    session_id integer,
    user_id integer,
    role character varying(20) DEFAULT 'guest'::character varying,
    confirmed boolean DEFAULT false,
    joined_at timestamp with time zone DEFAULT now(),
    left_at timestamp with time zone
);


ALTER TABLE public.session_guests OWNER TO splitdine_prod_user;

--
-- TOC entry 219 (class 1259 OID 18752)
-- Name: session_guests_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.session_guests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.session_guests_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3508 (class 0 OID 0)
-- Dependencies: 219
-- Name: session_guests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.session_guests_id_seq OWNED BY public.session_guests.id;


--
-- TOC entry 218 (class 1259 OID 18736)
-- Name: sessions; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.sessions (
    id integer NOT NULL,
    organizer_id integer,
    join_code character varying(6),
    status character varying(20) DEFAULT 'active'::character varying,
    restaurant_name character varying(255),
    receipt_image_url text,
    receipt_ocr_text text,
    receipt_processed boolean DEFAULT false,
    total_amount numeric(10,2) DEFAULT 0.00,
    tax_amount numeric(10,2) DEFAULT 0.00,
    tip_amount numeric(10,2) DEFAULT 0.00,
    service_charge numeric(10,2) DEFAULT 0.00,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.sessions OWNER TO splitdine_prod_user;

--
-- TOC entry 217 (class 1259 OID 18735)
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sessions_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3509 (class 0 OID 0)
-- Dependencies: 217
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- TOC entry 3279 (class 2604 OID 18725)
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- TOC entry 3310 (class 2604 OID 18792)
-- Name: final_splits id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.final_splits ALTER COLUMN id SET DEFAULT nextval('public.final_splits_id_seq'::regclass);


--
-- TOC entry 3306 (class 2604 OID 18782)
-- Name: item_assignments id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.item_assignments ALTER COLUMN id SET DEFAULT nextval('public.item_assignments_id_seq'::regclass);


--
-- TOC entry 3298 (class 2604 OID 18766)
-- Name: receipt_items id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.receipt_items ALTER COLUMN id SET DEFAULT nextval('public.receipt_items_id_seq'::regclass);


--
-- TOC entry 3320 (class 2604 OID 18808)
-- Name: session_activity_log id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_activity_log ALTER COLUMN id SET DEFAULT nextval('public.session_activity_log_id_seq'::regclass);


--
-- TOC entry 3294 (class 2604 OID 18756)
-- Name: session_guests id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_guests ALTER COLUMN id SET DEFAULT nextval('public.session_guests_id_seq'::regclass);


--
-- TOC entry 3285 (class 2604 OID 18739)
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- TOC entry 3323 (class 2606 OID 18734)
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- TOC entry 3346 (class 2606 OID 18803)
-- Name: final_splits final_splits_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.final_splits
    ADD CONSTRAINT final_splits_pkey PRIMARY KEY (id);


--
-- TOC entry 3344 (class 2606 OID 18787)
-- Name: item_assignments item_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.item_assignments
    ADD CONSTRAINT item_assignments_pkey PRIMARY KEY (id);


--
-- TOC entry 3339 (class 2606 OID 18777)
-- Name: receipt_items receipt_items_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.receipt_items
    ADD CONSTRAINT receipt_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3353 (class 2606 OID 18813)
-- Name: session_activity_log session_activity_log_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_activity_log
    ADD CONSTRAINT session_activity_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3335 (class 2606 OID 18761)
-- Name: session_guests session_guests_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_guests
    ADD CONSTRAINT session_guests_pkey PRIMARY KEY (id);


--
-- TOC entry 3331 (class 2606 OID 18751)
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 3324 (class 1259 OID 18814)
-- Name: idx_app_user_email; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_app_user_email ON public.app_user USING btree (email);


--
-- TOC entry 3325 (class 1259 OID 18815)
-- Name: idx_app_user_last_active; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_app_user_last_active ON public.app_user USING btree (last_active_at);


--
-- TOC entry 3347 (class 1259 OID 18827)
-- Name: idx_final_splits_session; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_final_splits_session ON public.final_splits USING btree (session_id);


--
-- TOC entry 3348 (class 1259 OID 18828)
-- Name: idx_final_splits_user; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_final_splits_user ON public.final_splits USING btree (user_id);


--
-- TOC entry 3340 (class 1259 OID 18825)
-- Name: idx_item_assignments_item; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_item_assignments_item ON public.item_assignments USING btree (item_id);


--
-- TOC entry 3341 (class 1259 OID 18824)
-- Name: idx_item_assignments_session; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_item_assignments_session ON public.item_assignments USING btree (session_id);


--
-- TOC entry 3342 (class 1259 OID 18826)
-- Name: idx_item_assignments_user; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_item_assignments_user ON public.item_assignments USING btree (user_id);


--
-- TOC entry 3336 (class 1259 OID 18823)
-- Name: idx_receipt_items_category; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_category ON public.receipt_items USING btree (category);


--
-- TOC entry 3337 (class 1259 OID 18822)
-- Name: idx_receipt_items_session; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_session ON public.receipt_items USING btree (session_id);


--
-- TOC entry 3349 (class 1259 OID 18831)
-- Name: idx_session_activity_created; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_activity_created ON public.session_activity_log USING btree (created_at);


--
-- TOC entry 3350 (class 1259 OID 18829)
-- Name: idx_session_activity_session; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_activity_session ON public.session_activity_log USING btree (session_id);


--
-- TOC entry 3351 (class 1259 OID 18830)
-- Name: idx_session_activity_user; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_activity_user ON public.session_activity_log USING btree (user_id);


--
-- TOC entry 3332 (class 1259 OID 18820)
-- Name: idx_session_participants_session; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_session ON public.session_guests USING btree (session_id);


--
-- TOC entry 3333 (class 1259 OID 18821)
-- Name: idx_session_participants_user; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_user ON public.session_guests USING btree (user_id);


--
-- TOC entry 3326 (class 1259 OID 18819)
-- Name: idx_sessions_created_at; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_created_at ON public.sessions USING btree (created_at);


--
-- TOC entry 3327 (class 1259 OID 18816)
-- Name: idx_sessions_join_code; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_join_code ON public.sessions USING btree (join_code);


--
-- TOC entry 3328 (class 1259 OID 18817)
-- Name: idx_sessions_organizer; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_organizer ON public.sessions USING btree (organizer_id);


--
-- TOC entry 3329 (class 1259 OID 18818)
-- Name: idx_sessions_status; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_status ON public.sessions USING btree (status);


--
-- TOC entry 3502 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO splitdine_prod_user;


-- Completed on 2025-07-10 23:11:06

--
-- PostgreSQL database dump complete
--

