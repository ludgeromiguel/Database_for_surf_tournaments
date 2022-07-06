DROP schema if EXISTS campeonatos_de_surf;
CREATE schema campeonatos_de_surf default character set utf8;
USE campeonatos_de_surf;

CREATE TABLE atleta (
    id_atleta int(5) not null auto_increment,
    nome char(50) not null,
    idade int(3) not null,
    peso float(5,2) not null,
    contacto int(15) not null,
    cod_postal char(10) not null,
    primary key(`id_atleta`)
);

CREATE TABLE codigo_postal (
	cod_postal char(10) not null,
    cidade char(30) not null,
    pais char(30) not null,
    primary key(`cod_postal`)
);

CREATE TABLE campeonato (
	id_campeonato int(5) not null auto_increment,
    ano int(4) not null,
    nome_campeonato char(100) not null,
    modalidade char(30) not null,
    premio float(15,2) not null,
    primary key(`id_campeonato`)
);

CREATE TABLE atletas_campeonato (
	id_atleta int(5) not null,
    id_campeonato int(5) not null,
    pontuacao_total int(10) DEFAULT 0,
    primary key(`id_atleta`,`id_campeonato`)
);

CREATE TABLE prova (
	id_prova int(5) not null auto_increment,
    id_campeonato int(5) not null,
    id_atleta int(5) not null,
    cod_postal char(10) not null,
    tempo_prova time not null,
    pontuacao_prova int(4) not null,
    primary key(`id_prova`)
);

ALTER TABLE atletas_campeonato 
    ADD CONSTRAINT atletas_campeonato_fk_atleta
    FOREIGN KEY (id_atleta)
    REFERENCES atleta(id_atleta)
	ON DELETE CASCADE;
    
ALTER TABLE atletas_campeonato 
    ADD CONSTRAINT atletas_campeonato_fk_campeonato
    FOREIGN KEY (id_campeonato)
    REFERENCES campeonato(id_campeonato);
    
ALTER TABLE atleta
	ADD CONSTRAINT atleta_fk_codigo_postal
    FOREIGN KEY	 (cod_postal)
    REFERENCES codigo_postal(cod_postal); 
    
ALTER TABLE prova
	ADD CONSTRAINT prova_fk_codigo_postal
    FOREIGN KEY	 (cod_postal)
    REFERENCES codigo_postal(cod_postal); 
    
ALTER TABLE prova
	ADD CONSTRAINT prova_fk_campeonato_e_atleta
    FOREIGN KEY	 (id_campeonato,id_atleta)
    REFERENCES atletas_campeonato(id_campeonato,id_atleta);


-- Criação da view para os campeonatos de um atleta ordenados
CREATE VIEW `lista_campeonatos_atleta` 
AS (SELECT atleta.id_atleta, atleta.nome, campeonato.*, atletas_campeonato.pontuacao_total
	FROM atleta
	INNER JOIN atletas_campeonato
		ON atletas_campeonato.id_atleta = atleta.id_atleta
	INNER JOIN campeonato
		ON atletas_campeonato.id_campeonato = campeonato.id_campeonato
        ORDER BY id_atleta, id_campeonato);

CREATE VIEW `lista_melhores_pontuacoes`
	as( SELECT atletas_campeonato.id_atleta, atletas_campeonato.id_campeonato, atletas_campeonato.pontuacao_total
		FROM atletas_campeonato
        ORDER BY atletas_campeonato.pontuacao_total DESC);

-- Ciração de um stored procedure para listar as pontuações por cada atleta
delimiter $$
create procedure get_pontuacoes_por_atleta()
BEGIN
	SELECT atleta.id_atleta, atleta.nome, Sum(atletas_campeonato.pontuacao_total) AS total_pontuacoes
		FROM atleta
		INNER JOIN atletas_campeonato
			ON atleta.id_atleta = atletas_campeonato.id_atleta
		GROUP BY id_atleta;
END $$
delimiter ;


-- Check no peso e idade para entrar nas conformidades
delimiter $$
CREATE TRIGGER idade_check BEFORE INSERT
	ON atleta
	FOR EACH ROW
		IF NEW.idade < 18 THEN
			SIGNAL SQLSTATE '50001' SET MESSAGE_TEXT = 'O atleta tem de ter no minímo 18 anos.';
		ELSEIF NEW.idade > 70 THEN
			SIGNAL SQLSTATE '50001' SET MESSAGE_TEXT = 'O atleta não pode ter mais que 70 anos.';
		END IF $$
CREATE TRIGGER peso_check BEFORE INSERT
	ON atleta
	FOR EACH ROW
		IF NEW.peso < 30 THEN 
			SIGNAL SQLSTATE '50001' SET MESSAGE_TEXT = 'O atleta tem de ter pelo menos 30kg.';
		ELSEIF NEW.peso > 100 THEN
			SIGNAL SQLSTATE '50001' SET MESSAGE_TEXT = 'O atleta tem de ter no máximo 100kg.';
		END IF $$
delimiter ;

-- Se inserirem uma prova, a pontuacao será também alterada na tabela dos atletas_campeonatos.
delimiter $$
CREATE TRIGGER atualizar_pontuacoes_totais_i AFTER INSERT
	ON prova
	FOR EACH ROW
	begin
		DECLARE v_pontuacao_prova double;
		DECLARE v_pontuacao_total double;
    
		SELECT pontuacao_total into v_pontuacao_total from atletas_campeonato WHERE id_atleta = NEW.id_atleta AND id_campeonato = NEW.id_campeonato;
		set v_pontuacao_total = v_pontuacao_total + NEW.pontuacao_prova;
    
		UPDATE atletas_campeonato set pontuacao_total = v_pontuacao_total where id_atleta = NEW.id_atleta AND id_campeonato = NEW.id_campeonato;
	end $$
delimiter ;

-- Se deletarem uma das provas, a pontuacao será também alterada na tabela dos atletas_campeonatos.
delimiter $$
CREATE TRIGGER atualizar_pontuacoes_totais_d AFTER DELETE
	ON prova
	FOR EACH ROW
	begin
		DECLARE v_pontuacao_prova double;
		DECLARE v_pontuacao_total double;
    
		SELECT pontuacao_total into v_pontuacao_total from atletas_campeonato WHERE id_atleta = OLD.id_atleta AND id_campeonato = OLD.id_campeonato;
		set v_pontuacao_total = v_pontuacao_total - OLD.pontuacao_prova;
    
		UPDATE atletas_campeonato set pontuacao_total = v_pontuacao_total where id_atleta = OLD.id_atleta AND id_campeonato = OLD.id_campeonato;
	end $$
delimiter ;

-- Se o nome vier com a primeira letra minúscula este trigger antes de o inserir na tabela ele coloca a primeira letra capitalizada.
delimiter $$
CREATE TRIGGER nome_capitalizado BEFORE INSERT
	ON atleta
	FOR EACH ROW
	begin
		set new.nome = CONCAT(UCASE(LEFT(new.nome, 1)), LCASE(SUBSTRING(new.nome, 2)));
	end $$
delimiter ;

-- --------------------------------------------------------------------------

INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7892-570','Cajolá','Guatemala');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7908-832','Hengshan','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3540-439','Opi','Nigeria');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1599-272','Orlovka','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0866-289','Köln','Germany');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9212-500','Uzunovo','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7409-987','Al Fuwayliq','Saudi Arabia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0861-486','Palecenan','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0307-884','Tanabe','Japan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6053-268','Donji Vakuf','Bosnia and Herzegovina');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3547-464','Amiens','France');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8074-301','Notodden','Norway');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9032-119','Itamaraju','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0275-444','Bungsuan','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9980-542','Somita','Gambia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8924-426','Chasŏng','North Korea');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5827-895','Matsue-shi','Japan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1061-776','Kramarzówka','Poland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7963-204','Jiangkou','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4691-901','Skomlin','Poland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2359-523','Glamang','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1805-199','Lagkadás','Greece');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2116-225','Tacarigua','Venezuela');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9087-030','Lecherías','Venezuela');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0862-166','Linjiang','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8689-934','Baoli','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2267-023','Chrastava','Czech Republic');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3041-925','Bogra','Bangladesh');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4938-741','Xianzong','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9147-481','Santa Cruz de El Seibo','Dominican Republic');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4761-084','Ili','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4069-876','Šilheřovice','Czech Republic');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3129-138','Zhongtang','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5794-297','Candelaria','Colombia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8507-466','Xinbu','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9631-567','Pandan','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3624-327','Krajan Selatan','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2015-031','Yaita','Japan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3754-600','Tower','Ireland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8015-564','Guayabetal','Colombia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7802-098','Alkmaar','Netherlands');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3688-575','Songqiao','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2317-598','Burunday','Kazakhstan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4641-044','Veinticinco de Mayo','Argentina');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3585-522','Fram','Paraguay');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6243-151','Bila Tserkva','Ukraine');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5394-256','Xiehu','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9723-793','Badarganj','Bangladesh');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8573-382','Arklow','Ireland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8623-283','Batanamang','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6999-804','Owando','Republic of the Congo');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4262-559','Khinjān','Afghanistan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9737-821','Mamu','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4107-827','Sanguanzhai','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3877-317','Irricana','Canada');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9312-700','Buyant','Mongolia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1323-017','Mpraeso','Ghana');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9955-997','Luobuqiongzi','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4395-267','Wenfeng Zhen','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9365-148','Shuangquan','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9574-634','Teluk Pinang','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6954-876','Kilcullen','Ireland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0624-366','Boulsa','Burkina Faso');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1776-274','Chikwawa','Malawi');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4165-503','Mibu','Japan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1120-341','Suntar','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4045-101','Curuzú Cuatiá','Argentina');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7533-074','Lorraine','Canada');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0834-195','Dagang','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1815-532','Chirilagua','El Salvador');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4595-689','Dongcheng','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6662-190','Katrineholm','Sweden');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5312-250','Krajan Jamprong','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2134-879','Janagdong','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2098-193','Brusyanka','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9751-621','Pétange','Luxembourg');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4013-251','Zheleznovodsk','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0847-076','Saint John','Canada');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4948-695','Ljutomer','Slovenia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1462-588','Tyringe','Sweden');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5841-035','Pag','Croatia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9850-259','Sūq Sibāḩ','Yemen');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4402-909','Barvinkove','Ukraine');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6959-745','Sendangwaru','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7113-304','Ximafang','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4188-665','Khun Han','Thailand');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0898-735','Olival','Portugal');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2948-810','Fuling','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2863-503','Ilovka','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5535-228','Rungis','France');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8319-979','Lidingö','Sweden');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5224-922','Cayambe','Ecuador');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5220-138','Karangtengah Lor','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0962-220','Mercedes','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2048-101','Shangcun','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3989-293','Täby','Sweden');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1301-392','Higashimurayama-shi','Japan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1956-770','Yuannan','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1717-690','Smyshlyayevka','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0378-620','Byera Village','Saint Vincent and the Grenadines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7123-956','Grubišno Polje','Croatia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9072-328','Ponjen','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9569-435','Skinnskatteberg','Sweden');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0732-084','Nahariya','Israel');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9910-080','Pingtan','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4726-489','Caruaru','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5702-875','Bergem','Luxembourg');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1601-432','Nanhuatang','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7762-100','Biting','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5265-072','Vrbovec','Czech Republic');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7252-996','Alexandria','Egypt');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1451-428','Oka','Canada');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2744-164','Carson City','United States');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1919-774','Jambesari','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4999-716','Banjar Pasekan','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8703-862','Lewin Kłodzki','Poland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3536-199','Qingshan','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0532-917','Mendes','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5874-111','Thoen','Thailand');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0682-816','Milano','Italy');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9040-205','Cabanaconde','Peru');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5842-970','San Miguel','Mexico');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5329-912','Stara Pazova','Serbia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7316-098','Uhryniv','Ukraine');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1383-649','Lewoeleng','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4801-642','Inuvik','Canada');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6409-458','Działdowo','Poland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0708-102','Mahébourg','Mauritius');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3149-606','Saparbay','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6402-151','Tuchlovice','Czech Republic');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9611-260','Calauan','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2871-249','Ryczów','Poland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7455-744','Oslo','Norway');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5477-231','Maticmatic','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4060-850','Morioka-shi','Japan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9820-678','Ognevka','Kazakhstan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8886-086','Vavatenina','Madagascar');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7428-467','Sovetskaya','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6258-022','Międzybrodzie Bialskie','Poland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4546-826','Manouba','Tunisia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5089-103','Wenquan','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1547-816','Chengshan','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4557-131','Dahuangwei','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6158-072','Mahong','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9231-425','Lérida','Colombia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5851-844','Ostrožská Lhota','Czech Republic');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6303-202','Thị Trấn Bắc Yên','Vietnam');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2459-673','Sutton','United Kingdom');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4226-008','Pomahuaca','Peru');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5669-874','Santiago De Compostela','Spain');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0980-495','Fulu','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7822-816','Lagoa Santa','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6269-813','Aduo','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2242-601','Torino','Italy');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1731-115','Xiaojian','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9185-809','Cegłów','Poland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5646-672','Dostoyevka','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7073-579','Куклиш','Macedonia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2678-887','Baláo','Ecuador');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1147-273','Outeiro Seco','Portugal');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6345-529','El Corpus','Honduras');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4893-975','Wanmao','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7199-239','Jabonga','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8613-418','Shagedu','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7169-170','Citalahab','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4432-625','Yehud','Israel');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3962-541','Guan’e','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6494-304','Kryvyy Rih','Ukraine');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5511-577','Tsimkavichy','Belarus');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8021-778','Sousse','Tunisia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3919-270','Além Paraíba','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7609-244','Thatta','Pakistan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5329-352','Nueva Esperanza','Mexico');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4453-841','Mukacheve','Ukraine');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8315-540','Lupak','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9592-367','Milovice','Czech Republic');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9893-361','Davila','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3600-785','Tadrart','Morocco');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5491-921','Stockholm','Sweden');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7189-651','Šalovci','Slovenia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6248-051','Nankai','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8942-752','Bali','Cameroon');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7106-786','Wolfsberg','Austria');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5735-205','Normandin','Canada');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4824-560','Lindavista','Mexico');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6757-173','Budapest','Hungary');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2252-482','Ciudad Nueva','Dominican Republic');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2340-442','Guanchao','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1479-499','Biris Daja','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8196-430','Ipu','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3233-800','El Guapinol','Honduras');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9249-452','Rio','Portugal');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2945-430','Torres Vedras','Portugal');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9256-463','Kajisara','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1775-094','Muramvya','Burundi');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4233-461','Vicente Guerrero','Mexico');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8634-237','Sadananya','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0512-213','Santa Cruz Muluá','Guatemala');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4239-986','Khulm','Afghanistan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2990-727','Nogliki','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8167-141','Fangshan','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9319-411','Rumphi','Malawi');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3405-848','Dongke','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2668-402','Burnside','United Kingdom');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3480-535','Novoye Leushino','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9191-262','Philadelphia','United States');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5564-178','Takaishi','Japan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3320-237','Kariaí','Greece');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9450-127','Sruni','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3995-396','Pueblo Nuevo','Colombia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3782-996','Zhuli','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2514-024','Tanjung Raja','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9118-719','Lijiapu','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6384-433','Ordzhonikidzevskaya','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5582-397','Polo','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9498-235','Jingning Chengguanzhen','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9110-401','Fort Erie','Canada');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3815-210','Bibinje','Croatia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1076-096','São Jerônimo','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4880-233','Dakhla','Western Sahara');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6876-919','Rendeng','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3509-159','Hanfeng','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7583-996','Jepuro','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2543-534','Qal‘ah-ye Shahr','Afghanistan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4758-177','Oliveiras','Portugal');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3375-328','Huikou','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7623-562','Osvaldo Cruz','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3573-616','Tonga','Cameroon');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7126-138','Krzanowice','Poland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0037-151','Miskolc','Hungary');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2997-265','Rio Negrinho','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5120-259','Aného','Togo');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1593-088','Nevinnomyssk','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7783-151','Sarreguemines','France');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4838-629','Pira','Peru');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8582-659','Wenfu','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5491-160','Kuleqi','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0021-711','Runan','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0807-133','Dorval','Canada');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6797-290','Georgiyevsk','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4609-075','Kabanga','Tanzania');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1594-739','Safi','Jordan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7916-091','Mabini','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2180-983','Turus','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7356-650','Huskvarna','Sweden');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0964-482','Rāiwind','Pakistan');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3110-031','Shuitianhe','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1947-586','Popayán','Colombia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4231-061','Shāzand','Iran');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1018-981','Canedo','Portugal');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6485-524','Dongtou','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8843-715','Laweueng','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0668-632','Oguta','Nigeria');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6371-522','Valkeakoski','Finland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0265-762','Fkih Ben Salah','Morocco');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7584-726','Tubungan','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4861-573','Samālūţ','Egypt');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5755-510','Yanwang','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2960-615','Brotas','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9119-065','Gbawe','Ghana');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3378-593','Macaíba','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7153-138','Hualgayoc','Peru');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0629-098','Piraí do Sul','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8186-514','Xiaopingba','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8081-501','Ban Lam Luk Ka','Thailand');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('0825-419','Los Frentones','Argentina');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1941-591','Tuanai','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7048-824','Boli','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5729-175','Kryevidh','Albania');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2597-080','Kharabali','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5350-397','Wulipu','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2411-527','Luoping','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8728-500','Hausjärvi','Finland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6027-742','Cachimayo','Peru');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('5217-461','Murcia','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7947-538','Nema','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3173-180','Tremembé','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4248-047','Paamiut','Greenland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9396-297','Bukabu','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2940-580','Vienne','France');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6976-063','Coro','Venezuela');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2566-723','Nanjia','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6288-547','Guanting','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2118-480','Kropachëvo','Russia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8653-464','Dublin','Ireland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9925-724','Loimaan Kunta','Finland');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1647-917','Nanyang','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4586-908','Granja','Portugal');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('2532-328','Baquero Norte','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('3079-387','Banjar Pangkungkarung Kangin','Indonesia');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9499-167','Seixal','Portugal');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1380-088','Nālūt','Libya');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9630-599','Yandian','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('8889-635','Sallanches','France');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7743-004','Ierápetra','Greece');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('6716-884','Purac','Philippines');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('4310-645','Gouveia','Portugal');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('1771-205','Tupaciguara','Brazil');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('9252-635','Bayan Hot','China');
INSERT INTO codigo_postal(cod_postal,cidade,pais) VALUES ('7834-451','Fryčovice','Czech Republic');


insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (1, 'Gaye', 19, 90.08, 964158810, '8843-715');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (2, 'Mervin', 61, 50.47, 965024828, '6494-304');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (3, 'Billy', 18, 56.8, 962227514, '2871-249');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (4, 'Oralia', 54, 47.79, 963970204, '4726-489');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (5, 'Colet', 18, 43.8, 963044573, '5350-397');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (6, 'Amargo', 49, 87.5, 962332460, '3149-606');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (7, 'Curran', 59, 58.52, 962316798, '3995-396');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (8, 'Deva', 32, 39.14, 967313804, '0980-495');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (9, 'Cory', 67, 60.17, 968849599, '9820-678');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (10, 'Cammy', 18, 31.16, 968494907, '0532-917');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (11, 'Ginni', 46, 63.78, 960441576, '2940-580');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (12, 'Rubia', 70, 90.86, 964958014, '9110-401');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (13, 'Aretha', 19, 48.61, 964649540, '8703-862');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (14, 'Codi', 61, 44.02, 968726234, '9191-262');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (15, 'Leah', 21, 76.01, 964714417, '9893-361');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (16, 'Eustace', 38, 98.51, 965013101, '3375-328');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (17, 'Albrecht', 46, 44.13, 960074475, '9498-235');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (18, 'Marshal', 25, 53.45, 966217739, '4432-625');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (19, 'Sharlene', 50, 71.18, 962093681, '2411-527');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (20, 'Lenard', 66, 48.75, 960480471, '5669-874');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (21, 'Karyn', 55, 62.71, 960322547, '4861-573');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (22, 'Inglebert', 38, 40.09, 961461628, '4248-047');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (23, 'Lamond', 27, 78.57, 963146854, '2997-265');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (24, 'Alley', 23, 43.56, 963403898, '8728-500');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (25, 'Salmon', 18, 97.53, 968296172, '9319-411');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (26, 'Liz', 59, 34.7, 968045428, '5851-844');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (27, 'Estell', 60, 45.58, 962389702, '6027-742');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (28, 'Nichol', 68, 59.65, 966065792, '2960-615');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (29, 'Byrom', 70, 46.66, 966050936, '1775-094');
insert into atleta (id_atleta, nome, idade, peso, contacto, cod_postal) values (30, 'Diane-marie', 66, 91.98, 968756136, '4609-075');


INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (1,2014,'vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien','Skate',12600.76);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (2,2022,'hac habitasse platea dictumst etiam faucibus cursus urna','Bodysurf',21382.11);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (3,2014,'luctus nec molestie sed justo pellentesque viverra pede','Skate',867202.89);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (4,2013,'et eros vestibulum ac est lacinia nisi venenatis tristique fusce congue diam id ornare','Stand up paddle',822870.0);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (5,2018,'nullam molestie nibh in lectus pellentesque at nulla suspendisse potenti cras in purus eu','Skate',176776.86);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (6,2018,'est phasellus sit amet erat nulla tempus','Longboard',391497.48);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (7,2021,'nulla eget eros elementum pellentesque quisque porta','Kneeboarding',70627.03);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (8,2012,'ut massa volutpat convallis morbi odio','Kneeboarding',718162.69);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (9,2014,'nam dui proin leo odio porttitor id consequat in consequat','Bodyboard',415620.43);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (10,2022,'diam neque vestibulum eget vulputate ut ultrices vel augue vestibulum ante ipsum primis in faucibus','Bodysurf',92091.0);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (11,2021,'in faucibus orci luctus et ultrices posuere cubilia curae donec pharetra','Longboard',156348.22);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (12,2018,'sollicitudin mi sit amet lobortis sapien sapien non mi integer ac neque duis bibendum morbi','Bodysurf',392635.16);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (13,2012,'nam ultrices libero non mattis pulvinar nulla pede ullamcorper augue a suscipit nulla','Stand up paddle',133080.34);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (14,2011,'maecenas rhoncus aliquam lacus morbi quis tortor id','Skimboard',342324.47);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (15,2013,'in hac habitasse platea dictumst maecenas ut','Bodysurf',865838.83);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (16,2020,'enim in tempor turpis nec euismod scelerisque quam turpis adipiscing lorem vitae mattis nibh ligula','Bodyboard',219436.76);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (17,2017,'ipsum dolor sit amet consectetuer adipiscing elit proin risus praesent lectus vestibulum','Stand up paddle',748043.25);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (18,2011,'dui nec nisi volutpat eleifend donec ut dolor morbi vel lectus in quam fringilla rhoncus','Bodysurf',384270.04);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (19,2014,'turpis a pede posuere nonummy integer non velit donec','Skate',935225.34);
INSERT INTO campeonato(id_campeonato,ano,nome_campeonato,modalidade,premio) VALUES (20,2021,'ac nibh fusce lacus purus aliquet at feugiat non','Kneeboarding',87826.0);


INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (1,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (2,2);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (3,5);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (6,6);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (7,7);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (24,7);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (29,2);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (27,4);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (2,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (19,6);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (25,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (17,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (3,13);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (7,5);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (30,9);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (20,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (23,8);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (11,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (22,5);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (14,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (9,4);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (5,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (10,7);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (12,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (8,6);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (26,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (29,1);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (20,19);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (30,3);
INSERT INTO atletas_campeonato(id_atleta,id_campeonato) VALUES (14,20);

INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (1,1,1,'3600-785','1:50:52',500);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (2,1,1,'7783-151','0:17:01',250);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (3,2,2,'1018-981','1:55:46',1000);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (4,7,7,'0265-762','0:49:51',30);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (5,6,19,'1941-591','0:43:54',200);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (6,5,3,'5729-175','1:34:10',200);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (7,4,27,'8728-500','0:46:28',150);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (8,7,7,'5329-912','1:46:20',128);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (9,7,7,'5120-259','1:01:09',90);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (10,7,7,'9249-452','1:06:36',150);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (11,7,7,'4453-841','1:21:30',150);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (12,4,27,'4432-625','0:23:35',150);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (13,4,27,'6269-813','1:47:01',150);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (14,4,27,'4231-061','1:16:34',100);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (15,4,27,'8081-501','0:25:33',100);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (16,1,1,'9820-678','0:44:00',100);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (17,1,1,'9119-065','0:04:35',100);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (18,7,24,'7123-956','1:01:07',150);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (19,7,24,'4758-177','0:56:44',66);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (20,7,24,'4248-047','0:27:17',25);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (21,7,24,'5491-160','1:55:25',26);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (22,3,30,'3919-270','0:52:12',90);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (23,3,30,'1947-586','1:22:02',90);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (24,3,30,'6402-151','1:18:45',777);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (25,3,30,'3378-593','0:33:30',700);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (26,3,30,'2744-164','1:43:02',800);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (27,3,30,'1919-774','0:34:51',230);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (28,1,1,'0682-816','0:12:39',74);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (29,1,25,'2597-080','1:29:44',95);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (30,1,25,'3079-387','1:13:27',333);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (31,1,25,'6876-919','1:29:42',125);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (32,2,2,'9231-425','0:08:29',500);
INSERT INTO prova(id_prova,id_campeonato,id_atleta,cod_postal,tempo_prova,pontuacao_prova) VALUES (33,2,2,'0964-482','0:49:03',150);

-- -------------------------------------------------------------------------------------------------------------------------
UPDATE atleta
SET nome = 'Professor Marco', idade= 35, peso = 85.60, contacto = 914391391, cod_postal = '2945-430'
WHERE id_atleta = 10;

SELECT *
	FROM atleta
    WHERE id_atleta = 10;

SELECT * FROM atleta;

insert into atleta values (32, 'rui', 25, 66, 962316798, '0898-735');
SELECT * 
	FROM atleta
    WHERE id_atleta = 32;
    
SELECT * FROM ATLETA;

SELECT *
from atleta a
left join atletas_campeonato b
ON a.id_atleta = b.id_atleta
WHERE id_campeonato = 1;

SELECT COUNT(*) as n_torneios, a.id_atleta
from atleta a
inner join atletas_campeonato b
ON a.id_atleta = b.id_atleta
GROUP BY a.id_atleta
-- WHERE id_campeonato = 1;

INSERT INTO atleta VALUES (id_atleta,

SELECT *
FROM ATLETA
INNER JOIN CODIGO_POSTAL
ON atleta.cod_postal = codigo_postal.cod_postal
WHERE codigo_postal.pais = "Portugal"
GROUP BY atleta.id_atleta;

SELECT * 
FROM ATLETA, codigo_postal
WHERE atleta.cod_postal = codigo_postal.cod_postal AND codigo_postal.pais = "Portugal"
GROUP BY atleta.id_atleta;

SELECT  b.id_atleta,a.id_campeonato, a.pontuacao_total
	FROM atleta b
    LEFT JOIN atletas_campeonato a 
    ON b.id_atleta = a.id_atleta
    ORDER BY id_atleta;
    
SELECT  b.id_atleta,a.id_campeonato, a.pontuacao_total
	FROM atleta b
    INNER JOIN atletas_campeonato a 
    ON b.id_atleta = a.id_atleta
    ORDER BY id_atleta;
    
SELECT  b.id_atleta,a.id_campeonato, a.pontuacao_total
	FROM atleta b
    left join atletas_campeonato a 
    ON b.id_atleta = a.id_atleta
    WHERE a.id_campeonato IS NULL
    ORDER BY id_atleta DESC;
    
SELECT * FROM lista_campeonatos_atleta;
call get_pontuacoes_por_atleta;
SELECT * FROM lista_melhores_pontuacoes;


