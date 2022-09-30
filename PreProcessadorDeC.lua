--  _______        _           _ _                   _           _               _____      
-- |__   __|      | |         | | |                 | |         | |             |  __ \     
--    | |_ __ __ _| |__   __ _| | |__   ___       __| | ___     | |             | |__) |    
--    | | '__/ _` | '_ \ / _` | | '_ \ / _ \     / _` |/ _ \    | |             |  ___/     
--    | | | | (_| | |_) | (_| | | | | | (_) |   | (_| |  __/    | |____    _    | |       _ 
--    |_|_|  \__,_|_.__/ \__,_|_|_| |_|\___/     \__,_|\___|    |______|  (_)   |_|      (_)
--                                                                                         
--  Aluno: Gustavo Freitas                                                             Matéria: Línguagens de Programação                                                                   
--  Objetivo: Implementar um "pre-processador" para C que consiga:
--  1 - Remover comentários
--  2 - Expandir #include e #define
--  3 - Remova quebras de linha, espaços e tabulações quando possível
--
--  Linguagem: LUA 5.4.4
--  https://www.lua.org/
--
-- Esse é meu primeiro código em Lua.
--

local Abrir = io.open

--Lê o arquivo dado um endereço
local function Ler_Arq(Endereco)
    local Arq = Abrir(Endereco, "rb")
    if not Arq then 
        print("Erro ao abrir arquivo")
        return nil 
    end
    local ArqC = Arq:read "*a"
    Arq:close()
    return ArqC
end

--Conta a ocorrência de aspas, ignorando o caso: \". 
local function Aspas(Codigo)
    local AspaFim = 1
    local AspasReal = 0
    local AspasFalso = 0
    while true do
        AspaI,AspaJ=string.find(Codigo,'["]',AspaFim)
        if AspaI==nil then break end
        AspasReal = AspasReal + 1
        AspaFim=AspaJ + 1
    end
    AspaFim = 1
    while true do
        local AspaI,AspaJ=string.find(Codigo,'\\'..'\"',AspaFim)
        if AspaI==nil then break end
        AspasFalso = AspasFalso + 1
        AspaFim=AspaJ + 1
    end  
    
    AspaFim = (AspasReal - AspasFalso)
    return AspaFim
end

--Substitui os Include's
local function Inclui(InclV,Codigo)
    local ArqInc = Abrir(InclV, "rb")
    if not ArqInc then
        print("!!!!! ERRO: Arquivo de #include nao encontrado. :( !!!!!")
        return nil
    end
    local CodigoInc = ArqInc:read "*a"
    ArqInc:close()
    local InclV2 = "#include(%s+)"..'\"'..InclV..'\"'  
    InclV = "#include(%s+)<"..InclV..">"
    Codigo = Codigo:gsub(InclV2,CodigoInc)
    Codigo = Codigo:gsub(InclV,CodigoInc)
    return Codigo
end

--Loop de Include's entre < > ; IncJ obtém a posição final do nome do arquivo, IncI obtém o inicio.
local function IncluiAux(Codigo)
    local _, IncJ = string.find(Codigo, "#include(%s+)<(%w+).(%w+)")
    local _, IncI = string.find(Codigo, "#include(%s+)<")
    while (IncJ ~= nil) do                                          
        IncJ = string.sub(Codigo,IncI+1,IncJ)                       
        Codigo = Inclui(IncJ,Codigo)
        _, IncJ = string.find(Codigo, "#include(%s+)<(%w+).(%w+)")
        _, IncI = string.find(Codigo, "#include(%s+)<")
    end
    return Codigo
end

--Loop de Include's entre " " ; Funciona igual a função acima. (Ctrl-V mesmo, desculpa. ( ╥﹏╥) ) 
local function IncluiAuxAspas(Codigo)
    local _, IncJ = string.find(Codigo, "#include(%s+)"..'\"'.."(%w+).(%w+)")
    local _, IncI = string.find(Codigo, "#include(%s+)"..'\"')
    while (IncJ ~= nil) do
        IncJ = string.sub(Codigo,IncI+1,IncJ)
        Codigo = Inclui(IncJ,Codigo)
        _, IncJ = string.find(Codigo, "#include(%s+)"..'\"'.."(%w+).(%w+)")
        _, IncI = string.find(Codigo, "#include(%s+)"..'\"')
    end
    return Codigo
end

--Loop de Define's
--
-- #define    TEXT  ( 5 + 3 + 1 + 8 + 0 + 0 + 8)
-- a          b  c  d                          e      f
--
-- a = StartDef / b = IdentifI / c = IdentifJ / d = FuncI / e = FuncJ / f = EndDef
--
local function Definiu(Codigo)
    local StartDef, IdentifI = string.find(Codigo, "#define(%s+)")
    while (StartDef ~= nil) do
        local _, IdentifJ = string.find(Codigo, "#define(%s+)(%S+)")
        local _, FuncI = string.find(Codigo, "#define(%s+)(%S+)(%s+)")
        local FuncJ,EndDef = string.find(Codigo, "(%s+)\n", FuncI)
        local ParteAnterior = string.sub(Codigo,1,StartDef-1)
        local PartePosterior = string.sub(Codigo,EndDef)  
        IdentifI = string.sub(Codigo,IdentifI+1,IdentifJ)    
        FuncI = string.sub(Codigo,FuncI+1,FuncJ-1)
        PartePosterior = PartePosterior:gsub(IdentifI,FuncI)
        Codigo = ParteAnterior..PartePosterior
        StartDef, IdentifI = string.find(Codigo, "#define(%s+)")
    end
    return Codigo
end

--Remove comentarios de uma linha //
local function ComentarioSingular(Codigo)
    Codigo = Codigo:gsub("//.-\n", '')
    return Codigo
end

--Remove comentários de mais de uma linha /* */
local function ComentarioMultiLinha(Codigo)
    Codigo = Codigo:gsub("/%*.-%*/", '')
    return Codigo
end

--Remove quebra de linhas e tabulações
local function QuebraLTab(Codigo)
    Codigo = Codigo:gsub("[\r\n\v\t]", '')
    return Codigo
end

--Substitui quando existem diversos espaços
local function Espacos(Codigo)
    local Espac3 = 1
    while true do
        Espac1, Espac2 = string.find(Codigo,"(%s)(%s+)",Espac3)
        if (Espac1 == nil) then break end
        ParteAnterior = string.sub(Codigo,1,Espac1)
        local EspAs = 0
        EspAs = Aspas(ParteAnterior)
        if (EspAs == nil or EspAs % 2 == 0) then
            PartePosterior = string.sub(Codigo,Espac2+1)
            Codigo = ParteAnterior..PartePosterior
        end           
        Espac3 = Espac2+1       
    end
    
    return Codigo
end

--Substitui espaços entre símbolos
local function Espacos2(Codigo)
    local Espac1 = 1
    while true do
        Espac1, _ = string.find(Codigo,"(%s)(%W)",Espac1)
        if (Espac1 == nil) then break end        
        ParteAnterior = string.sub(Codigo,1,Espac1-1)
        EspAs = 0
        EspAs = Aspas(ParteAnterior)
        if (EspAs == nil or EspAs % 2 == 0) then
            PartePosterior = string.sub(Codigo,Espac1+1)
            Codigo = ParteAnterior..PartePosterior
        end
        Espac1 = Espac1+1
    end
    Espac1 = 1
    while true do
        Espac1, _ = string.find(Codigo,"(%W)(%s)",Espac1)
        if (Espac1 == nil) then break end        
        ParteAnterior = string.sub(Codigo,1,Espac1-1)
        EspAs = 0
        EspAs = Aspas(ParteAnterior)
        if (EspAs == nil or EspAs % 2 == 0) then
            PartePosterior = string.sub(Codigo,Espac1+1)
            Codigo = ParteAnterior..PartePosterior
        end
        Espac1 = Espac1+1
    end

    return Codigo
end

--Executa as funções
print("Insira o nome / diretorio do arquivo (Incluindo o formato):")
print("(Lembre-se de incluir os arquivos dos #include's)\n")
local Diret = io.read("*l") 
local Codigo = Ler_Arq(Diret)
Codigo = IncluiAux(Codigo)
Codigo = IncluiAuxAspas(Codigo)
Codigo = Definiu(Codigo)
Codigo = ComentarioSingular(Codigo)
Codigo = ComentarioMultiLinha(Codigo)
Codigo = QuebraLTab(Codigo)
Codigo = Espacos(Codigo)
Codigo = Espacos2(Codigo)
local out = Abrir("CodigoOut.txt", "w")
out:write(Codigo)
print("\nArquivo gerado com sucesso.\n")

