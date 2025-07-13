--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 17.4

-- Started on 2025-07-13 14:35:46

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
-- TOC entry 228 (class 1259 OID 18977)
-- Name: app_user; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.app_user (
    id integer NOT NULL,
    email character varying(255),
    phone character varying(20),
    display_name character varying(100) NOT NULL,
    password_hash character varying(255),
    is_anonymous boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    last_active_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.app_user OWNER TO splitdine_prod_user;

--
-- TOC entry 227 (class 1259 OID 18976)
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
-- TOC entry 3499 (class 0 OID 0)
-- Dependencies: 227
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- TOC entry 224 (class 1259 OID 18925)
-- Name: final_splits; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.final_splits (
    id integer NOT NULL,
    session_id integer NOT NULL,
    user_id integer NOT NULL,
    subtotal_amount numeric(10,2) DEFAULT 0.00,
    tax_share numeric(10,2) DEFAULT 0.00,
    tip_share numeric(10,2) DEFAULT 0.00,
    service_charge_share numeric(10,2) DEFAULT 0.00,
    total_amount numeric(10,2) DEFAULT 0.00,
    paid boolean DEFAULT false,
    payment_method character varying(50),
    payment_reference character varying(255),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.final_splits OWNER TO splitdine_prod_user;

--
-- TOC entry 223 (class 1259 OID 18924)
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
-- TOC entry 3500 (class 0 OID 0)
-- Dependencies: 223
-- Name: final_splits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.final_splits_id_seq OWNED BY public.final_splits.id;


--
-- TOC entry 222 (class 1259 OID 18916)
-- Name: item_assignments; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.item_assignments (
    id integer NOT NULL,
    session_id integer NOT NULL,
    item_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.item_assignments OWNER TO splitdine_prod_user;

--
-- TOC entry 221 (class 1259 OID 18915)
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
-- TOC entry 3501 (class 0 OID 0)
-- Dependencies: 221
-- Name: item_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.item_assignments_id_seq OWNED BY public.item_assignments.id;


--
-- TOC entry 220 (class 1259 OID 18901)
-- Name: receipt_items; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.receipt_items (
    id integer NOT NULL,
    session_id integer NOT NULL,
    name character varying(255) NOT NULL,
    price numeric(10,2) NOT NULL,
    quantity integer DEFAULT 1,
    category character varying(50) DEFAULT 'food'::character varying,
    description text,
    parsed_confidence numeric(3,2) DEFAULT 0.00,
    manually_edited boolean DEFAULT false,
    added_by_user_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    share character varying(20)
);


ALTER TABLE public.receipt_items OWNER TO splitdine_prod_user;

--
-- TOC entry 219 (class 1259 OID 18900)
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
-- TOC entry 3502 (class 0 OID 0)
-- Dependencies: 219
-- Name: receipt_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.receipt_items_id_seq OWNED BY public.receipt_items.id;


--
-- TOC entry 226 (class 1259 OID 18940)
-- Name: session_activity_log; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.session_activity_log (
    id integer NOT NULL,
    session_id integer NOT NULL,
    user_id integer,
    action_type character varying(50) NOT NULL,
    action_details jsonb,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.session_activity_log OWNER TO splitdine_prod_user;

--
-- TOC entry 225 (class 1259 OID 18939)
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
-- TOC entry 3503 (class 0 OID 0)
-- Dependencies: 225
-- Name: session_activity_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.session_activity_log_id_seq OWNED BY public.session_activity_log.id;


--
-- TOC entry 218 (class 1259 OID 18892)
-- Name: session_participants; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.session_participants (
    id integer NOT NULL,
    session_id integer NOT NULL,
    user_id integer NOT NULL,
    role character varying(20) DEFAULT 'guest'::character varying,
    joined_at timestamp with time zone DEFAULT now(),
    left_at timestamp with time zone
);


ALTER TABLE public.session_participants OWNER TO splitdine_prod_user;

--
-- TOC entry 217 (class 1259 OID 18891)
-- Name: session_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.session_participants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.session_participants_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3504 (class 0 OID 0)
-- Dependencies: 217
-- Name: session_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.session_participants_id_seq OWNED BY public.session_participants.id;


--
-- TOC entry 216 (class 1259 OID 18876)
-- Name: sessions; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.sessions (
    id integer NOT NULL,
    organizer_id integer NOT NULL,
    session_name character varying(255),
    location character varying(255) NOT NULL,
    session_date date NOT NULL,
    session_time time without time zone,
    description text,
    join_code character varying(6) NOT NULL,
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
-- TOC entry 215 (class 1259 OID 18875)
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
-- TOC entry 3505 (class 0 OID 0)
-- Dependencies: 215
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- TOC entry 3311 (class 2604 OID 18980)
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- TOC entry 3300 (class 2604 OID 18928)
-- Name: final_splits id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.final_splits ALTER COLUMN id SET DEFAULT nextval('public.final_splits_id_seq'::regclass);


--
-- TOC entry 3297 (class 2604 OID 18919)
-- Name: item_assignments id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.item_assignments ALTER COLUMN id SET DEFAULT nextval('public.item_assignments_id_seq'::regclass);


--
-- TOC entry 3290 (class 2604 OID 18904)
-- Name: receipt_items id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.receipt_items ALTER COLUMN id SET DEFAULT nextval('public.receipt_items_id_seq'::regclass);


--
-- TOC entry 3309 (class 2604 OID 18943)
-- Name: session_activity_log id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_activity_log ALTER COLUMN id SET DEFAULT nextval('public.session_activity_log_id_seq'::regclass);


--
-- TOC entry 3287 (class 2604 OID 18895)
-- Name: session_participants id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_participants ALTER COLUMN id SET DEFAULT nextval('public.session_participants_id_seq'::regclass);


--
-- TOC entry 3279 (class 2604 OID 18879)
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- TOC entry 3349 (class 2606 OID 18987)
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- TOC entry 3338 (class 2606 OID 18938)
-- Name: final_splits final_splits_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.final_splits
    ADD CONSTRAINT final_splits_pkey PRIMARY KEY (id);


--
-- TOC entry 3336 (class 2606 OID 18923)
-- Name: item_assignments item_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.item_assignments
    ADD CONSTRAINT item_assignments_pkey PRIMARY KEY (id);


--
-- TOC entry 3331 (class 2606 OID 18914)
-- Name: receipt_items receipt_items_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.receipt_items
    ADD CONSTRAINT receipt_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3347 (class 2606 OID 18948)
-- Name: session_activity_log session_activity_log_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_activity_log
    ADD CONSTRAINT session_activity_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3326 (class 2606 OID 18899)
-- Name: session_participants session_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_participants
    ADD CONSTRAINT session_participants_pkey PRIMARY KEY (id);


--
-- TOC entry 3321 (class 2606 OID 18890)
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 3339 (class 1259 OID 18967)
-- Name: idx_final_splits_paid; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_final_splits_paid ON public.final_splits USING btree (paid);


--
-- TOC entry 3340 (class 1259 OID 18965)
-- Name: idx_final_splits_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_final_splits_session_id ON public.final_splits USING btree (session_id);


--
-- TOC entry 3341 (class 1259 OID 18966)
-- Name: idx_final_splits_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_final_splits_user_id ON public.final_splits USING btree (user_id);


--
-- TOC entry 3332 (class 1259 OID 18963)
-- Name: idx_item_assignments_item_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_item_assignments_item_id ON public.item_assignments USING btree (item_id);


--
-- TOC entry 3333 (class 1259 OID 18962)
-- Name: idx_item_assignments_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_item_assignments_session_id ON public.item_assignments USING btree (session_id);


--
-- TOC entry 3334 (class 1259 OID 18964)
-- Name: idx_item_assignments_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_item_assignments_user_id ON public.item_assignments USING btree (user_id);


--
-- TOC entry 3327 (class 1259 OID 18960)
-- Name: idx_receipt_items_added_by_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_added_by_user_id ON public.receipt_items USING btree (added_by_user_id);


--
-- TOC entry 3328 (class 1259 OID 18961)
-- Name: idx_receipt_items_category; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_category ON public.receipt_items USING btree (category);


--
-- TOC entry 3329 (class 1259 OID 18959)
-- Name: idx_receipt_items_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_session_id ON public.receipt_items USING btree (session_id);


--
-- TOC entry 3342 (class 1259 OID 18970)
-- Name: idx_session_activity_log_action_type; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_activity_log_action_type ON public.session_activity_log USING btree (action_type);


--
-- TOC entry 3343 (class 1259 OID 18971)
-- Name: idx_session_activity_log_created_at; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_activity_log_created_at ON public.session_activity_log USING btree (created_at);


--
-- TOC entry 3344 (class 1259 OID 18968)
-- Name: idx_session_activity_log_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_activity_log_session_id ON public.session_activity_log USING btree (session_id);


--
-- TOC entry 3345 (class 1259 OID 18969)
-- Name: idx_session_activity_log_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_activity_log_user_id ON public.session_activity_log USING btree (user_id);


--
-- TOC entry 3322 (class 1259 OID 18958)
-- Name: idx_session_participants_role; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_role ON public.session_participants USING btree (role);


--
-- TOC entry 3323 (class 1259 OID 18956)
-- Name: idx_session_participants_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_session_id ON public.session_participants USING btree (session_id);


--
-- TOC entry 3324 (class 1259 OID 18957)
-- Name: idx_session_participants_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_user_id ON public.session_participants USING btree (user_id);


--
-- TOC entry 3315 (class 1259 OID 18955)
-- Name: idx_sessions_created_at; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_created_at ON public.sessions USING btree (created_at);


--
-- TOC entry 3316 (class 1259 OID 18952)
-- Name: idx_sessions_join_code; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_join_code ON public.sessions USING btree (join_code);


--
-- TOC entry 3317 (class 1259 OID 18954)
-- Name: idx_sessions_location; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_location ON public.sessions USING btree (location);


--
-- TOC entry 3318 (class 1259 OID 18951)
-- Name: idx_sessions_organizer_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_organizer_id ON public.sessions USING btree (organizer_id);


--
-- TOC entry 3319 (class 1259 OID 18953)
-- Name: idx_sessions_session_date; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_session_date ON public.sessions USING btree (session_date);


--
-- TOC entry 3498 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO splitdine_prod_user;


-- Completed on 2025-07-13 14:35:47

--
-- PostgreSQL database dump complete
--

