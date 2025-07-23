--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 17.4

-- Started on 2025-07-23 21:01:34

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

--
-- TOC entry 2 (class 3079 OID 19376)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 3563 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 223 (class 1259 OID 18977)
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
-- TOC entry 222 (class 1259 OID 18976)
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
-- TOC entry 3564 (class 0 OID 0)
-- Dependencies: 222
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- TOC entry 221 (class 1259 OID 18901)
-- Name: guest_choice; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.guest_choice (
    id integer NOT NULL,
    session_id integer NOT NULL,
    user_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    split_item boolean,
    item_id integer
);


ALTER TABLE public.guest_choice OWNER TO splitdine_prod_user;

--
-- TOC entry 231 (class 1259 OID 19356)
-- Name: menu_item; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.menu_item (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.menu_item OWNER TO splitdine_prod_user;

--
-- TOC entry 230 (class 1259 OID 19355)
-- Name: menu_item_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.menu_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menu_item_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3565 (class 0 OID 0)
-- Dependencies: 230
-- Name: menu_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.menu_item_id_seq OWNED BY public.menu_item.id;


--
-- TOC entry 229 (class 1259 OID 19319)
-- Name: menu_list; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.menu_list (
    id integer NOT NULL,
    menu_item character varying(255) NOT NULL,
    synonym character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.menu_list OWNER TO splitdine_prod_user;

--
-- TOC entry 228 (class 1259 OID 19318)
-- Name: menu_list_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.menu_list_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menu_list_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3566 (class 0 OID 0)
-- Dependencies: 228
-- Name: menu_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.menu_list_id_seq OWNED BY public.menu_list.id;


--
-- TOC entry 235 (class 1259 OID 19459)
-- Name: menu_search_log; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.menu_search_log (
    id integer NOT NULL,
    user_input character varying(255) NOT NULL,
    matched_menu_item_id integer,
    guest_id integer,
    matched boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.menu_search_log OWNER TO splitdine_prod_user;

--
-- TOC entry 234 (class 1259 OID 19458)
-- Name: menu_search_log_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.menu_search_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menu_search_log_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3567 (class 0 OID 0)
-- Dependencies: 234
-- Name: menu_search_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.menu_search_log_id_seq OWNED BY public.menu_search_log.id;


--
-- TOC entry 233 (class 1259 OID 19366)
-- Name: menu_synonym; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.menu_synonym (
    id integer NOT NULL,
    menu_item_id integer NOT NULL,
    synonym character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.menu_synonym OWNER TO splitdine_prod_user;

--
-- TOC entry 232 (class 1259 OID 19365)
-- Name: menu_synonym_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.menu_synonym_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menu_synonym_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3568 (class 0 OID 0)
-- Dependencies: 232
-- Name: menu_synonym_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.menu_synonym_id_seq OWNED BY public.menu_synonym.id;


--
-- TOC entry 220 (class 1259 OID 18900)
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
-- TOC entry 3569 (class 0 OID 0)
-- Dependencies: 220
-- Name: receipt_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.receipt_items_id_seq OWNED BY public.guest_choice.id;


--
-- TOC entry 225 (class 1259 OID 19106)
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
-- TOC entry 224 (class 1259 OID 19105)
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
-- TOC entry 3570 (class 0 OID 0)
-- Dependencies: 224
-- Name: receipt_scans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.receipt_scans_id_seq OWNED BY public.receipt_scans.id;


--
-- TOC entry 217 (class 1259 OID 18876)
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
-- TOC entry 219 (class 1259 OID 18892)
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
-- TOC entry 218 (class 1259 OID 18891)
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
-- TOC entry 3571 (class 0 OID 0)
-- Dependencies: 218
-- Name: session_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.session_participants_id_seq OWNED BY public.session_guest.id;


--
-- TOC entry 227 (class 1259 OID 19145)
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
-- TOC entry 226 (class 1259 OID 19144)
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
-- TOC entry 3572 (class 0 OID 0)
-- Dependencies: 226
-- Name: session_receipt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.session_receipt_id_seq OWNED BY public.session_receipt.id;


--
-- TOC entry 216 (class 1259 OID 18875)
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
-- TOC entry 3573 (class 0 OID 0)
-- Dependencies: 216
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.session.id;


--
-- TOC entry 3355 (class 2604 OID 18980)
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- TOC entry 3352 (class 2604 OID 18904)
-- Name: guest_choice id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.guest_choice ALTER COLUMN id SET DEFAULT nextval('public.receipt_items_id_seq'::regclass);


--
-- TOC entry 3370 (class 2604 OID 19359)
-- Name: menu_item id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.menu_item ALTER COLUMN id SET DEFAULT nextval('public.menu_item_id_seq'::regclass);


--
-- TOC entry 3368 (class 2604 OID 19322)
-- Name: menu_list id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.menu_list ALTER COLUMN id SET DEFAULT nextval('public.menu_list_id_seq'::regclass);


--
-- TOC entry 3374 (class 2604 OID 19462)
-- Name: menu_search_log id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.menu_search_log ALTER COLUMN id SET DEFAULT nextval('public.menu_search_log_id_seq'::regclass);


--
-- TOC entry 3372 (class 2604 OID 19369)
-- Name: menu_synonym id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.menu_synonym ALTER COLUMN id SET DEFAULT nextval('public.menu_synonym_id_seq'::regclass);


--
-- TOC entry 3360 (class 2604 OID 19109)
-- Name: receipt_scans id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.receipt_scans ALTER COLUMN id SET DEFAULT nextval('public.receipt_scans_id_seq'::regclass);


--
-- TOC entry 3343 (class 2604 OID 18879)
-- Name: session id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- TOC entry 3350 (class 2604 OID 18895)
-- Name: session_guest id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_guest ALTER COLUMN id SET DEFAULT nextval('public.session_participants_id_seq'::regclass);


--
-- TOC entry 3365 (class 2604 OID 19148)
-- Name: session_receipt id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_receipt ALTER COLUMN id SET DEFAULT nextval('public.session_receipt_id_seq'::regclass);


--
-- TOC entry 3394 (class 2606 OID 18987)
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- TOC entry 3404 (class 2606 OID 19364)
-- Name: menu_item menu_item_name_key; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.menu_item
    ADD CONSTRAINT menu_item_name_key UNIQUE (name);


--
-- TOC entry 3406 (class 2606 OID 19362)
-- Name: menu_item menu_item_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.menu_item
    ADD CONSTRAINT menu_item_pkey PRIMARY KEY (id);


--
-- TOC entry 3402 (class 2606 OID 19327)
-- Name: menu_list menu_list_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.menu_list
    ADD CONSTRAINT menu_list_pkey PRIMARY KEY (id);


--
-- TOC entry 3413 (class 2606 OID 19466)
-- Name: menu_search_log menu_search_log_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.menu_search_log
    ADD CONSTRAINT menu_search_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3409 (class 2606 OID 19374)
-- Name: menu_synonym menu_synonym_menu_item_id_synonym_key; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.menu_synonym
    ADD CONSTRAINT menu_synonym_menu_item_id_synonym_key UNIQUE (menu_item_id, synonym);


--
-- TOC entry 3411 (class 2606 OID 19372)
-- Name: menu_synonym menu_synonym_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.menu_synonym
    ADD CONSTRAINT menu_synonym_pkey PRIMARY KEY (id);


--
-- TOC entry 3392 (class 2606 OID 18914)
-- Name: guest_choice receipt_items_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.guest_choice
    ADD CONSTRAINT receipt_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3398 (class 2606 OID 19118)
-- Name: receipt_scans receipt_scans_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.receipt_scans
    ADD CONSTRAINT receipt_scans_pkey PRIMARY KEY (id);


--
-- TOC entry 3388 (class 2606 OID 18899)
-- Name: session_guest session_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_guest
    ADD CONSTRAINT session_participants_pkey PRIMARY KEY (id);


--
-- TOC entry 3400 (class 2606 OID 19152)
-- Name: session_receipt session_receipt_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_receipt
    ADD CONSTRAINT session_receipt_pkey PRIMARY KEY (id);


--
-- TOC entry 3384 (class 2606 OID 18890)
-- Name: session sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 3389 (class 1259 OID 18960)
-- Name: idx_receipt_items_added_by_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_added_by_user_id ON public.guest_choice USING btree (user_id);


--
-- TOC entry 3390 (class 1259 OID 18959)
-- Name: idx_receipt_items_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_session_id ON public.guest_choice USING btree (session_id);


--
-- TOC entry 3395 (class 1259 OID 19119)
-- Name: idx_receipt_scans_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_scans_session_id ON public.receipt_scans USING btree (session_id);


--
-- TOC entry 3396 (class 1259 OID 19120)
-- Name: idx_receipt_scans_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_scans_user_id ON public.receipt_scans USING btree (uploaded_by_user_id);


--
-- TOC entry 3385 (class 1259 OID 18956)
-- Name: idx_session_participants_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_session_id ON public.session_guest USING btree (session_id);


--
-- TOC entry 3386 (class 1259 OID 18957)
-- Name: idx_session_participants_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_user_id ON public.session_guest USING btree (user_id);


--
-- TOC entry 3378 (class 1259 OID 18955)
-- Name: idx_sessions_created_at; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_created_at ON public.session USING btree (created_at);


--
-- TOC entry 3379 (class 1259 OID 18952)
-- Name: idx_sessions_join_code; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_join_code ON public.session USING btree (join_code);


--
-- TOC entry 3380 (class 1259 OID 18954)
-- Name: idx_sessions_location; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_location ON public.session USING btree (location);


--
-- TOC entry 3381 (class 1259 OID 18951)
-- Name: idx_sessions_organizer_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_organizer_id ON public.session USING btree (organizer_id);


--
-- TOC entry 3382 (class 1259 OID 18953)
-- Name: idx_sessions_session_date; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_session_date ON public.session USING btree (session_date);


--
-- TOC entry 3407 (class 1259 OID 19457)
-- Name: idx_synonym_trgm; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_synonym_trgm ON public.menu_synonym USING gin (synonym public.gin_trgm_ops);


--
-- TOC entry 3562 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO splitdine_prod_user;


-- Completed on 2025-07-23 21:01:35

--
-- PostgreSQL database dump complete
--

