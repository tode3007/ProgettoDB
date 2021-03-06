drop database azienda;
create database azienda;
\c azienda;
----------------------------------------------------------------
-- COPIARE DA QUI IN POI PER CREARE LE TABELLE LA PRIMA VOLTA --
----------------------------------------------------------------
create domain dom_cf as varchar check(value ~ '[A-Z]{6}[0-9]{2}[A-Z]{1}[0-9]{2}[A-Z][0-9]{3}[A-Z]');
create domain dom_partita as varchar check(value ~ '[A-Z]{2}[0-9]{4}');
create domain dom_email as varchar check(value ~'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$');
create domain dom_piva as varchar check(value ~ '[0-9]{11}');
create domain dom_tel as varchar check(value ~ '[0-9]{10}');
create domain dom_articolo_comp as varchar check(value ~ '[A-Z]{2}[0-9]{6}');
create domain dom_articolo_vend as varchar check(value ~ '[A-Z]{2}[0-9]{8}');


CREATE TABLE capo_area (
  cf dom_cf primary key,
  nome varchar(50) not null,
  cognome varchar(50) not null,
  nascita date not null,
  indirizzo varchar(100) not null,
  sesso varchar(1) check (sesso in ('m', 'f')) not null,
  mercato varchar(25) not null unique);

    CREATE TABLE agente (
        cf dom_cf primary key,
        nome varchar(50) not null,
        cognome varchar(50) not null,
        nascita date not null,
        indirizzo varchar(100) not null,
        sesso varchar(1) check (sesso in ('m', 'f')) not null,
        capo_area dom_cf not null);

    CREATE TABLE mercato (
    	nome varchar(25) primary key);

    CREATE TABLE regione (
    	mercato varchar(25) primary key);

    CREATE TABLE macro_zona (
    	mercato varchar(25) primary key);

    CREATE TABLE formazione (
        macro_zona varchar(25),
        regione varchar(25),
        primary key(macro_zona, regione));

    CREATE TABLE sede (
        citta varchar(50) not null,
        indirizzo varchar(100) not null,
        cliente dom_piva not null,
        primary key(citta, indirizzo));

    CREATE TABLE cliente (
        p_iva dom_piva primary key,
        nome varchar(50) not null,
        tel dom_tel not null unique,
        mail dom_email not null unique ,
        agente dom_cf not null,
        mercato varchar(25) not null);

    CREATE TABLE ordine (
        n_fattura integer primary key,
        costo_totale numeric not null ,
        data date not null,
        cliente dom_piva not null);

    CREATE TABLE linea_prodotto(
        nome varchar(25)primary key);

    CREATE TABLE fornitore (
        p_iva dom_piva primary key,
        nome varchar(50) not null);

    CREATE TABLE articolo_venduto(
        codice dom_articolo_vend primary key,
        prezzo_articolo float not null,
        peso float not null,
        descrizione varchar(100),
        scadenza date not null,
        confezionamento date not null,
        ordine integer not null,
        quantita int not null,
        linea_prodotto varchar not null ,
        articolo_comprato dom_articolo_comp not null,
        partita dom_partita not null);

    CREATE TABLE partita (
     codice dom_partita primary key,
     quantita integer not null,
     qualita_scelta varchar(7) check (qualita_scelta in ('prima', 'seconda','terza')) not null,
     bio boolean not null,
     razza varchar not null,
     tipo varchar not null,
     costo_acquisto numeric not null,
     costo_stoccaggio numeric not null,
     costo_spedizione numeric not null,
     p_iva dom_piva not null
     );

    CREATE TABLE articolo_comprato (
     codice dom_articolo_comp,
     partita dom_partita,
     eta numeric not null,
     prezzo numeric not null,
     primary key(codice,partita));


-----------------------------------------------------------
-- Aggiunta chiavi esterne:
-- ATTENZIONE:controllare on update e on delete
-----------------------------------------------------------

ALTER TABLE agente ADD CONSTRAINT constraint_fk FOREIGN KEY (capo_area) REFERENCES capo_area (cf) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE capo_area ADD CONSTRAINT constraint_fk FOREIGN KEY (mercato) REFERENCES mercato (nome) ON DELETE SET NULL ON UPDATE CASCADE INITIALLY DEFERRED DEFERRABLE;
ALTER TABLE regione ADD CONSTRAINT constraint_fk FOREIGN KEY (nome) REFERENCES mercato (nome) ON DELETE SET NULL ON UPDATE CASCADE INITIALLY DEFERRED DEFERRABLE;
ALTER TABLE macro_zona ADD CONSTRAINT constraint_fk FOREIGN KEY (nome) REFERENCES mercato (nome) ON DELETE SET NULL ON UPDATE CASCADE INITIALLY DEFERRED DEFERRABLE;
ALTER TABLE formazione ADD CONSTRAINT constraint_fk_macro_zona FOREIGN KEY (macro_zona) REFERENCES macro_zona (nome) ON DELETE CASCADE ON UPDATE CASCADE INITIALLY DEFERRED DEFERRABLE;
ALTER TABLE formazione ADD CONSTRAINT constraint_fk_regione FOREIGN KEY (regione) REFERENCES regione (nome) ON DELETE CASCADE ON UPDATE CASCADE INITIALLY DEFERRED DEFERRABLE;
ALTER TABLE cliente ADD CONSTRAINT constraint_fk_mercato FOREIGN KEY (mercato) REFERENCES mercato (nome) ON DELETE NO ACTION ON UPDATE CASCADE INITIALLY DEFERRED DEFERRABLE;
ALTER TABLE cliente ADD CONSTRAINT constraint_fk_agente FOREIGN KEY (agente) REFERENCES agente (cf) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE sede ADD CONSTRAINT constraint_fk FOREIGN KEY (cliente) REFERENCES cliente (p_iva)  ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ordine ADD CONSTRAINT constraint_fk FOREIGN KEY (cliente) REFERENCES cliente (p_iva) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE articolo_venduto ADD CONSTRAINT constraint_fk_ordine FOREIGN KEY (ordine) REFERENCES ordine (n_fattura) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE articolo_venduto ADD CONSTRAINT constraint_fk_linea_prodotto FOREIGN KEY (linea_prodotto) REFERENCES linea_prodotto (nome) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE articolo_venduto ADD CONSTRAINT constraint_fk_articolo_comprato FOREIGN KEY (articolo_comprato,partita) REFERENCES articolo_comprato (codice,partita) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE articolo_comprato ADD CONSTRAINT constraint_partita FOREIGN KEY (partita) REFERENCES partita (codice) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE partita ADD CONSTRAINT constraint_p_iva FOREIGN KEY (p_iva) REFERENCES fornitore (p_iva) ON DELETE NO ACTION ON UPDATE CASCADE;

--All’interno della base di dati sono presenti altri tipi di vincoli che implicano la creazione di appositi trigger per essere rispettati:
--- -la data di scadenza di un articolo non deve essere posteriore alla data in cui viene effettuato un ordine con quell’articolo
--- -quando inserisco un cliente in un mercato, l’agente che lo segue deve essere coordinato dal capo area che gestisce quel mercato
--- -il costo totale di un ordine deve essere uguale alla quantità di ciascun articolo venduto contenuto moltiplicato per il suo prezzo
--- -il prezzo di ogni articolo comprato deve essere uguale alla somma dei costi di acquisto, spedizione e stoccaggio, divisa per la quantità di articoli comprati presenti nella partita
--- -un ORDINE da parte del CLIENTE non può avvenire in una data antecedente a quella attuale (questo vale per la modifica della data dell'ordine)

--Vincoli risolvibili con l’aggiunta di not null nella tabella:
--- -Tabella cliente: un cliente deve avere almeno un recapito telefonico ed almeno una mail

-- Di seguito sono riportati altri vincoli di integrità ancora da implementare:
 --un cliente deve avere almeno un recapito telefonico ed almeno una mail
--un cliente deve afferire ad un unico mercato, il\i numero\i di telefono e gli indirizzi mail devono essere unici
--un capo area deve gestire un unico mercato
--un agente deve essere coordinato da un unico capo-area
--uno specifico ordine è effettuato da un unico cliente
--ogni articolo_venduto deve appartenere ad un unico ordine e ad una linea di prodotto unica
--ogni partita è fornita da un unico fornitore


--Constraint numero 1: Data di confezionamento < data_scadenza
create or replace function check_date_valide(data_conf  date , data_scad  date) returns bool language plpgsql as $$     begin     return  data_conf < data_scad; end; $$ ;
alter  table  articolo_venduto add
 constraint  check_date_valide_ric
  check(check_date_valide(confezionamento ,scadenza ));

--Constraint numero 2: Data di ordine <= data odierna

create or replace function check_date_valide_ordine(data_ordine date) returns bool language plpgsql as $$     begin   return data_ordine<=current_date; end; $$ ;

alter  table  ordine add
 constraint  check_date_valide_ordine_ric
  check(check_date_valide_ordine(data));

--Il vincolo 1, diversamente dai precedenti vincoli sulle date, necessita di un trigger perché coinvolge attributi di tabelle diverse.
--Il codice seguente deve essere eseguito quando sarà inserito nella base un nuovo ARTICOLO_COMPRATO o quando se ne modifica la data di Scadenza.


create or replace function check_dateOrdine () returns trigger language plpgsql as
 $$
  begin
  perform *
  from ordine,articolo_venduto
  where  new.ordine=ordine.n_fattura and (new.scadenza > ordine.data);
if found
 then
	 return new;
else
    raise  exception 'Non è possibile vendere un articolo scaduto';
    return  null;
  end if;
end;
$$;

create  trigger modifica_ordine before update
  on  articolo_venduto for  each  row
   when (new.scadenza <> old.scadenza)
  execute  procedure check_dateOrdine();

create  trigger  newOrdine before  insert
  on  articolo_venduto for  each  row
  execute  procedure check_dateOrdine();

--Il vincolo 2 è necessario per garantire che non si creino inconsistenze nel ciclo trattato nella Sezione 3.3.2.
--Il codice seguente deve essere eseguito quando si inserisce un nuovo cliente oppure si modifica l’agente che segue il cliente o il mercato di appartenenza del cliente.
create  or  replace  function check_cliente() returns trigger language plpgsql as
 $$
   begin
   perform *
   from capo_area,agente,cliente
    where agente.capo_area=capo_area.cf and cliente.agente=agente.cf and
                 not exists(select *
                             from mercato
                             where cliente.mercato <> capo_area.mercato );
if found
 then
        raise  exception 'Non rispetta i vincoli';
        return  null;
 else
   return  new;
  end if;
end;
$$;

create  trigger  newCliente before insert
  on  cliente for  each  row
  execute  procedure check_cliente();

create  trigger cliente_modifica before update
  on  cliente for  each  row
   when ( new.agente  <> old.agente  or
            new.mercato  <> old.mercato)
  execute  procedure check_cliente();


--Data di un ordine non deve essere successiva alla data odierna (considero data in cui viene fatto l’ordine e non data in cui viene consegnato al cliente). Viene eseguito quando modifico data dell’ordine
create or replace function check_ordine() returns trigger language plpgsql as
 $$
   begin
   perform *
   from ordine
   where ordine.data>=current_date ;
if found
 then
        raise exception 'Non si può fare un ordine per il futuro';
        return  null;
 else
   return  new;
  end if;
end;
$$;

create  trigger modifica_ordine before update
  on  ordine for  each  row
   when ( new.data <> old.data)
  execute  procedure check_ordine();

--Per attributi derivati SQL non offre un costrutto, perciò è necessario creare dei trigger
--Attributi derivati :
--1)Tabella ordine: costo_totale = quantità * prezzo articolo (perchè attributo derivato)
--2)Tabella articolo_comprato: prezzo = (costo acquisto + spedizione + stoccaggio) \ quantità

--Implementazione primo trigger:
--Trigger differenti per inserimento e aggiornamento
--Devo modificare il campo costo_totale di ordine quando:
---Inserisco un nuovo articolo
---Modifico il campo prezzo_articolo o quantita di articolo_venduto


--Definiamo prima la funzione che servirà per calcolare il costo_totale:

create or replace function calcolo_costo(NumFattura integer)
returns float as
 $$
  declare
     prezzo float := 0;
  begin
     select prezzo into prezzo
     from ordine as o, articolo_venduto as av
     where av.ordine=o.n_fattura and o.n_fattura=NumFattura;
     return prezzo;
end;
$$ language plpgsql;

create or replace function calcolo_quantita(NumFattura integer)
returns float as
 $$
  declare
     quantita int:= 0;
  begin
     select quantita into quantita
     from ordine as o, articolo_venduto as av
     where av.ordine=o.n_fattura and o.n_fattura=NumFattura;
     return quantita;
end;
$$ language plpgsql;

create  or  replace  function insert_costo_ordine()
returns trigger language  plpgsql as
 $$
  begin
  update ordine
  set costo_totale= calcolo_costo(new.ordine)*calcolo_quantita(new.ordine)
  where new.ordine=ordine.n_fattura;
  return new;
 end;
$$;

create  trigger insert_ordine after insert
  on  articolo_venduto for  each  row
  execute  procedure insert_costo_ordine();

create  trigger modifica_articolo after update
  on  articolo_venduto for  each  row
   when (new.prezzo_articolo <> old.prezzo_articolo or
          new.quantita  <> old.quantita )
  execute  procedure insert_costo_ordine();

--2) Tabella articolo_comprato: prezzo = (costo acquisto + spedizione + stoccaggio) \ quantità

--Implementazione secondo trigger:
--Trigger differenti per inserimento e aggiornamento
--Devo modificare il campo prezzo di articolo_comprato quando:
--Inserisco un nuovo articolo
--Modifico il campo costo_acquisto o costo_stoccaggio o costo_spedizione o quantita di partita

--Definiamo prima la funzione che servirà per calcolare il prezzo:
create  or  replace  function calcolo_prezzo_articolo(partitaInput dom_partita)
returns float language  plpgsql as $$
declare
   prezzo_tot float :=0;
begin
  select sum(costo_spedizione + costo_stoccaggio + costo_acquisto) into prezzo_tot
  from partita as p, articolo_comprato as ac
  where p.codice=partitaInput and p.codice=ac.partita;
return prezzo_tot;
end;
$$ ;

create  or  replace  function calcolo_prezzo_articolo_conQuantita(partitaInput dom_partita)
returns float language  plpgsql as $$
declare
      quantita int:= 0;
begin
  select p.quantita into quantita
  from partita as p, articolo_comprato as ac
  where p.codice=partitaInput and p.codice=ac.partita;
return quantita;
end;
$$ ;

create  or  replace function insert_prezzo_articolo()
returns trigger language plpgsql as
 $$
  begin
    update articolo_comprato
    set prezzo=(calcolo_prezzo_articolo(new.partita)/calcolo_prezzo_articolo_conQuantita(new.partita))
    where new.partita=articolo_comprato.partita;
  return new;
 end;
$$;

create  trigger insert_articolo_comprato after insert
  on  articolo_comprato for each row
  execute  procedure insert_prezzo_articolo();

create  trigger modifica_articolo_comprato after update
  on  partita for  each  row
   when (new.quantita <> old.quantita or
         new.costo_spedizione  <> old.costo_spedizione or
         new.costo_acquisto  <> old.costo_acquisto or
         new.costo_stoccaggio <> old.costo_stoccaggio )
  execute  procedure insert_prezzo_articolo();
