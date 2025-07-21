--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 17.4

-- Started on 2025-07-21 22:54:33

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
-- TOC entry 222 (class 1259 OID 18977)
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
    last_active_at timestamp with time zone DEFAULT now(),
    email_verified boolean DEFAULT false,
    auth_token character varying(255),
    auth_token_expires timestamp with time zone
);


ALTER TABLE public.app_user OWNER TO splitdine_prod_user;

--
-- TOC entry 221 (class 1259 OID 18976)
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
-- TOC entry 3481 (class 0 OID 0)
-- Dependencies: 221
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- TOC entry 220 (class 1259 OID 18901)
-- Name: guest_choice; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.guest_choice (
    id integer NOT NULL,
    session_id integer NOT NULL,
    name character varying(255) NOT NULL,
    price numeric(10,2) NOT NULL,
    user_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    split_item boolean,
    item_id integer
);


ALTER TABLE public.guest_choice OWNER TO splitdine_prod_user;

--
-- TOC entry 228 (class 1259 OID 19196)
-- Name: raw_scan; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.raw_scan (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    scan_text text NOT NULL
);


ALTER TABLE public.raw_scan OWNER TO splitdine_prod_user;

--
-- TOC entry 227 (class 1259 OID 19195)
-- Name: raw_scan_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.raw_scan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.raw_scan_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3482 (class 0 OID 0)
-- Dependencies: 227
-- Name: raw_scan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.raw_scan_id_seq OWNED BY public.raw_scan.id;


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
-- TOC entry 3483 (class 0 OID 0)
-- Dependencies: 219
-- Name: receipt_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.receipt_items_id_seq OWNED BY public.guest_choice.id;


--
-- TOC entry 224 (class 1259 OID 19106)
-- Name: receipt_scans; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.receipt_scans (
    id integer NOT NULL,
    session_id integer NOT NULL,
    image_path text NOT NULL,
    ocr_text text,
    ocr_confidence numeric(3,2) DEFAULT 0.00,
    parsed_items jsonb,
    total_amount numeric(10,2),
    tax_amount numeric(10,2),
    service_charge numeric(10,2),
    processing_status character varying(20) DEFAULT 'pending'::character varying,
    uploaded_by_user_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT receipt_scans_processing_status_check CHECK (((processing_status)::text = ANY ((ARRAY['pending'::character varying, 'processing'::character varying, 'completed'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.receipt_scans OWNER TO splitdine_prod_user;

--
-- TOC entry 223 (class 1259 OID 19105)
-- Name: receipt_scans_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.receipt_scans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.receipt_scans_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3484 (class 0 OID 0)
-- Dependencies: 223
-- Name: receipt_scans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.receipt_scans_id_seq OWNED BY public.receipt_scans.id;


--
-- TOC entry 216 (class 1259 OID 18876)
-- Name: session; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.session (
    id integer NOT NULL,
    organizer_id integer NOT NULL,
    session_name character varying(255),
    location character varying(255) NOT NULL,
    session_date date NOT NULL,
    session_time time without time zone,
    description text,
    join_code character varying(6) NOT NULL,
    total_amount numeric(10,2) DEFAULT 0.00,
    tax_amount numeric(10,2) DEFAULT 0.00,
    item_amount numeric(10,2) DEFAULT 0.00,
    service_charge numeric(10,2) DEFAULT 0.00,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    extra_charge numeric(10,2),
    food_type character varying(100)
);


ALTER TABLE public.session OWNER TO splitdine_prod_user;

--
-- TOC entry 218 (class 1259 OID 18892)
-- Name: session_guest; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.session_guest (
    id integer NOT NULL,
    session_id integer NOT NULL,
    user_id integer NOT NULL,
    joined_at timestamp with time zone DEFAULT now(),
    left_at timestamp with time zone
);


ALTER TABLE public.session_guest OWNER TO splitdine_prod_user;

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
-- TOC entry 3485 (class 0 OID 0)
-- Dependencies: 217
-- Name: session_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.session_participants_id_seq OWNED BY public.session_guest.id;


--
-- TOC entry 226 (class 1259 OID 19145)
-- Name: session_receipt; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.session_receipt (
    id integer NOT NULL,
    session_id integer,
    item_name character varying(255),
    price numeric(10,2),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.session_receipt OWNER TO splitdine_prod_user;

--
-- TOC entry 225 (class 1259 OID 19144)
-- Name: session_receipt_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.session_receipt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.session_receipt_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3486 (class 0 OID 0)
-- Dependencies: 225
-- Name: session_receipt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.session_receipt_id_seq OWNED BY public.session_receipt.id;


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
-- TOC entry 3487 (class 0 OID 0)
-- Dependencies: 215
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.session.id;


--
-- TOC entry 3291 (class 2604 OID 18980)
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- TOC entry 3288 (class 2604 OID 18904)
-- Name: guest_choice id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.guest_choice ALTER COLUMN id SET DEFAULT nextval('public.receipt_items_id_seq'::regclass);


--
-- TOC entry 3304 (class 2604 OID 19199)
-- Name: raw_scan id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.raw_scan ALTER COLUMN id SET DEFAULT nextval('public.raw_scan_id_seq'::regclass);


--
-- TOC entry 3296 (class 2604 OID 19109)
-- Name: receipt_scans id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.receipt_scans ALTER COLUMN id SET DEFAULT nextval('public.receipt_scans_id_seq'::regclass);


--
-- TOC entry 3279 (class 2604 OID 18879)
-- Name: session id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- TOC entry 3286 (class 2604 OID 18895)
-- Name: session_guest id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_guest ALTER COLUMN id SET DEFAULT nextval('public.session_participants_id_seq'::regclass);


--
-- TOC entry 3301 (class 2604 OID 19148)
-- Name: session_receipt id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_receipt ALTER COLUMN id SET DEFAULT nextval('public.session_receipt_id_seq'::regclass);


--
-- TOC entry 3322 (class 2606 OID 18987)
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- TOC entry 3331 (class 2606 OID 19203)
-- Name: raw_scan raw_scan_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.raw_scan
    ADD CONSTRAINT raw_scan_pkey PRIMARY KEY (id);


--
-- TOC entry 3320 (class 2606 OID 18914)
-- Name: guest_choice receipt_items_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.guest_choice
    ADD CONSTRAINT receipt_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3326 (class 2606 OID 19118)
-- Name: receipt_scans receipt_scans_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.receipt_scans
    ADD CONSTRAINT receipt_scans_pkey PRIMARY KEY (id);


--
-- TOC entry 3316 (class 2606 OID 18899)
-- Name: session_guest session_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_guest
    ADD CONSTRAINT session_participants_pkey PRIMARY KEY (id);


--
-- TOC entry 3328 (class 2606 OID 19152)
-- Name: session_receipt session_receipt_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_receipt
    ADD CONSTRAINT session_receipt_pkey PRIMARY KEY (id);


--
-- TOC entry 3312 (class 2606 OID 18890)
-- Name: session sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 3329 (class 1259 OID 19204)
-- Name: idx_raw_scan_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_raw_scan_session_id ON public.raw_scan USING btree (session_id);


--
-- TOC entry 3317 (class 1259 OID 18960)
-- Name: idx_receipt_items_added_by_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_added_by_user_id ON public.guest_choice USING btree (user_id);


--
-- TOC entry 3318 (class 1259 OID 18959)
-- Name: idx_receipt_items_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_session_id ON public.guest_choice USING btree (session_id);


--
-- TOC entry 3323 (class 1259 OID 19119)
-- Name: idx_receipt_scans_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_scans_session_id ON public.receipt_scans USING btree (session_id);


--
-- TOC entry 3324 (class 1259 OID 19120)
-- Name: idx_receipt_scans_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_scans_user_id ON public.receipt_scans USING btree (uploaded_by_user_id);


--
-- TOC entry 3313 (class 1259 OID 18956)
-- Name: idx_session_participants_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_session_id ON public.session_guest USING btree (session_id);


--
-- TOC entry 3314 (class 1259 OID 18957)
-- Name: idx_session_participants_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_user_id ON public.session_guest USING btree (user_id);


--
-- TOC entry 3306 (class 1259 OID 18955)
-- Name: idx_sessions_created_at; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_created_at ON public.session USING btree (created_at);


--
-- TOC entry 3307 (class 1259 OID 18952)
-- Name: idx_sessions_join_code; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_join_code ON public.session USING btree (join_code);


--
-- TOC entry 3308 (class 1259 OID 18954)
-- Name: idx_sessions_location; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_location ON public.session USING btree (location);


--
-- TOC entry 3309 (class 1259 OID 18951)
-- Name: idx_sessions_organizer_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_organizer_id ON public.session USING btree (organizer_id);


--
-- TOC entry 3310 (class 1259 OID 18953)
-- Name: idx_sessions_session_date; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_session_date ON public.session USING btree (session_date);


--
-- TOC entry 3480 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO splitdine_prod_user;


-- Completed on 2025-07-21 22:54:34

--
-- PostgreSQL database dump complete
--

