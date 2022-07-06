-- -----------------------------------------------------
-- Criar a DB
-- -----------------------------------------------------
drop schema if exists `ginasio`;
create schema `ginasio` default character set utf8;

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`login`
-- -----------------------------------------------------
create table `ginasio`.`login` (
	`id` int not null auto_increment,
    `username` varchar(45) not null,
	`password` varchar(80) not null,
    `typeAccount` varchar(60) not null,
    `createdByAdmin` tinyint not null,
    `isActive` tinyint not null default 1,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`subscricao`
-- -----------------------------------------------------
create table `ginasio`.`subscricao` (
	`id` int not null auto_increment,
    `nome` varchar(45) not null,
    `preco` float not null,
    `isActive` tinyint not null default 1,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`cliente`
-- -----------------------------------------------------
create table `ginasio`.`cliente` (
	`id` int not null auto_increment,
    `primNome` varchar(45) not null,
    `ultNome` varchar(45) not null,
    `dataNascimento` date not null,
    `nif` int not null,
    `genero` varchar(1) not null,
    `telefone` int not null,
    `email` varchar(70) not null,
    `morada` varchar(70) not null,
    `isActive` tinyint not null default 1,
    `foto` varchar(70) null default null,
    `subscricao` int not null,
    `inicioSubscricao` date not null,
    `fimSubscricao` date not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`cargo`
-- -----------------------------------------------------
create table `ginasio`.`cargo` (
	`id` int not null auto_increment,
    `nome` varchar(45) not null,
    `nomeSistema` varchar(45) not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`funcionario`
-- -----------------------------------------------------
create table `ginasio`.`funcionario` (
	`id` int not null auto_increment,
    `primNome` varchar(45) not null,
    `ultNome` varchar(45) not null,
    `dataNascimento` date not null,
    `nif` int not null,
    `genero` varchar(1) not null,
    `telefone` int not null,
    `email` varchar(70) not null,
    `morada` varchar(70) not null,
    `isActive` tinyint not null default 1,
    `foto` varchar(70) null default null,
    `salario` float not null,
    `inicioContrato` date not null,
    `fimContrato` date not null,
    `turnoInicio` time not null,
    `turnoFim` time not null,
    `idTipoCargo` int not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`tipoReclamacao`
-- -----------------------------------------------------
create table `ginasio`.`tipoReclamacao` (
	`id` int not null auto_increment,
    `nome` varchar(45) not null,
    `nomeSistema` varchar(45) not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`livroReclamacao`
-- -----------------------------------------------------
create table `ginasio`.`livroReclamacao` (
	`id` int not null auto_increment,
    `descricao` varchar(500) not null,
    `idCliente` int not null,
    `idTipoReclamacao` int not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`tipoEquipamento`
-- -----------------------------------------------------
create table `ginasio`.`tipoEquipamento` (
	`id` int not null auto_increment,
    `nome` varchar(45) not null,
    `nomeSistema` varchar(45) not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`equipamento`
-- -----------------------------------------------------
create table `ginasio`.`equipamento` (
	`id` int not null auto_increment,
    `nome` varchar(45) not null,
    `quantidade` int not null,
    `idTipoEquipamento` int not null,
    `idFuncionario` int not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`modalidade`
-- -----------------------------------------------------
create table `ginasio`.`modalidade` (
	`id` int not null auto_increment,
    `nome` varchar(45) not null,
    `nomeSistema` varchar(45) not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`aula`
-- -----------------------------------------------------
create table `ginasio`.`aula` (
	`id` int not null auto_increment,
    `idModalidade` int not null,
    `nSala` int not null,
    `maxAlunos` int not null,
    `diaSemana` int not null,
    `hora` time not null,
    `idProfessor` int not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`aulasCliente`
-- -----------------------------------------------------
create table `ginasio`.`aulasCliente` (
	`idAula` int not null,
    `idCliente` int not null,
    primary key (`idAula`, `idCliente`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`avaliacaoFisica`
-- -----------------------------------------------------
create table `ginasio`.`avaliacaoFisica` (
	`id` int not null auto_increment,
    `idCliente` int not null,
    `peso` float not null,
    `tamanho` int not null,
    `gordura` float not null,
    `massaMuscular` float not null,
    `data` date not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`planoNutricional`
-- -----------------------------------------------------
create table `ginasio`.`planoNutricional` (
	`diaSemana` int not null,
    `idCliente` int not null,
    `pequenoAlmoco` varchar(250) not null,
    `lancheManha` varchar(250) not null,
    `almoco` varchar(250) not null,
    `lancheTarde` varchar(250) not null,
    `jantar` varchar(250) not null,
    `ceia` varchar(250) not null,
    primary key (`diaSemana`, `idCliente`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`extra`
-- -----------------------------------------------------
create table `ginasio`.`extra` (
	`id` int not null auto_increment,
    `nome` varchar(45) not null,
    `preco` float not null,
    primary key (`id`)
);

-- -----------------------------------------------------
-- Criar tabela `ginasio`.`extrasCliente`
-- -----------------------------------------------------
create table `ginasio`.`extrasCliente` (
	`idCliente` int not null,
    `idExtra` int not null,
    `quantidade` int not null,
    primary key (`idCliente`, `idExtra`)
);

-- -----------------------------------------------------
-- Criar FK para a tabela `ginasio`.`cliente`
-- -----------------------------------------------------
alter table `ginasio`.`cliente`
	add constraint `cliente_FK_subscricao`
    foreign key (`subscricao`)
    references subscricao(`id`);
    
-- -----------------------------------------------------
-- Criar FK para a tabela `ginasio`.`funcionario`
-- -----------------------------------------------------
alter table `ginasio`.`funcionario`
	add constraint `funcionario_FK_cargo`
    foreign key (`idTipoCargo`)
    references cargo(`id`);
    
-- -----------------------------------------------------
-- Criar FK para a tabela `ginasio`.`livroReclamacao`
-- -----------------------------------------------------
alter table `ginasio`.`livroReclamacao`
	add constraint `livroReclamacao_FK_cliente`
    foreign key (`idCliente`)
    references cliente(`id`);
    
alter table `ginasio`.`livroReclamacao`
	add constraint `livroReclamacao_FK_tipoReclamacao`
    foreign key (`idTipoReclamacao`)
    references tipoReclamacao(`id`);
    
-- -----------------------------------------------------
-- Criar FK para a tabela `ginasio`.`equipamento`
-- -----------------------------------------------------
alter table `ginasio`.`equipamento`
	add constraint `equipamento_FK_tipoEquipamento`
    foreign key (`idTipoEquipamento`)
    references tipoEquipamento(`id`);

alter table `ginasio`.`equipamento`
	add constraint `equipamento_FK_funcionario`
    foreign key (`idFuncionario`)
    references funcionario(`id`);
    
-- -----------------------------------------------------
-- Criar FK para a tabela `ginasio`.`aula`
-- -----------------------------------------------------
alter table `ginasio`.`aula`
	add constraint `aula_FK_modalidade`
    foreign key (`idModalidade`)
    references modalidade(`id`);
    
alter table `ginasio`.`aula`
	add constraint `aula_FK_professor`
    foreign key (`idProfessor`)
    references funcionario(`id`);
    
-- -----------------------------------------------------
-- Criar FK para a tabela `ginasio`.`aulasCliente`
-- -----------------------------------------------------
alter table `ginasio`.`aulasCliente`
	add constraint `aulasCliente_FK_cliente`
    foreign key (`idCliente`)
    references cliente(`id`);
    
alter table `ginasio`.`aulasCliente`
	add constraint `aulasCliente_FK_aula`
    foreign key (`idAula`)
    references aula(`id`);
    
-- -----------------------------------------------------
-- Criar FK para a tabela `ginasio`.`avaliacaoFisica`
-- -----------------------------------------------------
alter table `ginasio`.`avaliacaoFisica`
	add constraint `avaliacaoFisica_FK_cliente`
    foreign key (`idCliente`)
    references cliente(`id`);
    
-- -----------------------------------------------------
-- Criar FK para a tabela `ginasio`.`planoNutricional`
-- -----------------------------------------------------
alter table `ginasio`.`planoNutricional`
	add constraint `planoNutricional_FK_cliente`
    foreign key (`idCliente`)
    references cliente(`id`);
    
-- -----------------------------------------------------
-- Criar FK para a tabela `ginasio`.`extrasCliente`
-- -----------------------------------------------------
alter table `ginasio`.`extrasCliente`
	add constraint `extrasCliente_FK_cliente`
    foreign key (`idCliente`)
    references cliente(`id`);
    
alter table `ginasio`.`extrasCliente`
	add constraint `extrasCliente_FK_extra`
    foreign key (`idExtra`)
    references extra(`id`);