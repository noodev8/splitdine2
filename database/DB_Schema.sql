--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Ubuntu 16.9-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 17.4

-- Started on 2025-07-16 23:24:08

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
    last_active_at timestamp with time zone DEFAULT now()
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
-- TOC entry 3458 (class 0 OID 0)
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
    description text,
    user_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    split_item boolean
);


ALTER TABLE public.guest_choice OWNER TO splitdine_prod_user;

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
-- TOC entry 3459 (class 0 OID 0)
-- Dependencies: 219
-- Name: receipt_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.receipt_items_id_seq OWNED BY public.guest_choice.id;


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
-- TOC entry 3460 (class 0 OID 0)
-- Dependencies: 217
-- Name: session_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.session_participants_id_seq OWNED BY public.session_guest.id;


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
-- TOC entry 3461 (class 0 OID 0)
-- Dependencies: 215
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.session.id;


--
-- TOC entry 224 (class 1259 OID 18997)
-- Name: split_items; Type: TABLE; Schema: public; Owner: splitdine_prod_user
--

CREATE TABLE public.split_items (
    id integer NOT NULL,
    session_id integer NOT NULL,
    name character varying(255) NOT NULL,
    price numeric(10,2) NOT NULL,
    description text,
    added_by_user_id integer,
    guest_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.split_items OWNER TO splitdine_prod_user;

--
-- TOC entry 223 (class 1259 OID 18996)
-- Name: split_items_id_seq; Type: SEQUENCE; Schema: public; Owner: splitdine_prod_user
--

CREATE SEQUENCE public.split_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.split_items_id_seq OWNER TO splitdine_prod_user;

--
-- TOC entry 3462 (class 0 OID 0)
-- Dependencies: 223
-- Name: split_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: splitdine_prod_user
--

ALTER SEQUENCE public.split_items_id_seq OWNED BY public.split_items.id;


--
-- TOC entry 3281 (class 2604 OID 18980)
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- TOC entry 3278 (class 2604 OID 18904)
-- Name: guest_choice id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.guest_choice ALTER COLUMN id SET DEFAULT nextval('public.receipt_items_id_seq'::regclass);


--
-- TOC entry 3269 (class 2604 OID 18879)
-- Name: session id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- TOC entry 3276 (class 2604 OID 18895)
-- Name: session_guest id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_guest ALTER COLUMN id SET DEFAULT nextval('public.session_participants_id_seq'::regclass);


--
-- TOC entry 3285 (class 2604 OID 19000)
-- Name: split_items id; Type: DEFAULT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.split_items ALTER COLUMN id SET DEFAULT nextval('public.split_items_id_seq'::regclass);


--
-- TOC entry 3304 (class 2606 OID 18987)
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- TOC entry 3302 (class 2606 OID 18914)
-- Name: guest_choice receipt_items_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.guest_choice
    ADD CONSTRAINT receipt_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3298 (class 2606 OID 18899)
-- Name: session_guest session_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session_guest
    ADD CONSTRAINT session_participants_pkey PRIMARY KEY (id);


--
-- TOC entry 3294 (class 2606 OID 18890)
-- Name: session sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 3308 (class 2606 OID 19006)
-- Name: split_items split_items_pkey; Type: CONSTRAINT; Schema: public; Owner: splitdine_prod_user
--

ALTER TABLE ONLY public.split_items
    ADD CONSTRAINT split_items_pkey PRIMARY KEY (id);


--
-- TOC entry 3299 (class 1259 OID 18960)
-- Name: idx_receipt_items_added_by_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_added_by_user_id ON public.guest_choice USING btree (user_id);


--
-- TOC entry 3300 (class 1259 OID 18959)
-- Name: idx_receipt_items_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_receipt_items_session_id ON public.guest_choice USING btree (session_id);


--
-- TOC entry 3295 (class 1259 OID 18956)
-- Name: idx_session_participants_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_session_id ON public.session_guest USING btree (session_id);


--
-- TOC entry 3296 (class 1259 OID 18957)
-- Name: idx_session_participants_user_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_session_participants_user_id ON public.session_guest USING btree (user_id);


--
-- TOC entry 3288 (class 1259 OID 18955)
-- Name: idx_sessions_created_at; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_created_at ON public.session USING btree (created_at);


--
-- TOC entry 3289 (class 1259 OID 18952)
-- Name: idx_sessions_join_code; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_join_code ON public.session USING btree (join_code);


--
-- TOC entry 3290 (class 1259 OID 18954)
-- Name: idx_sessions_location; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_location ON public.session USING btree (location);


--
-- TOC entry 3291 (class 1259 OID 18951)
-- Name: idx_sessions_organizer_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_organizer_id ON public.session USING btree (organizer_id);


--
-- TOC entry 3292 (class 1259 OID 18953)
-- Name: idx_sessions_session_date; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_sessions_session_date ON public.session USING btree (session_date);


--
-- TOC entry 3305 (class 1259 OID 19008)
-- Name: idx_split_items_guest_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_split_items_guest_id ON public.split_items USING btree (guest_id);


--
-- TOC entry 3306 (class 1259 OID 19007)
-- Name: idx_split_items_session_id; Type: INDEX; Schema: public; Owner: splitdine_prod_user
--

CREATE INDEX idx_split_items_session_id ON public.split_items USING btree (session_id);


--
-- TOC entry 3457 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO splitdine_prod_user;


-- Completed on 2025-07-16 23:24:09

--
-- PostgreSQL database dump complete
--

