{####################################################################}
{###                                                              ###}
{###                           JOGO DE TETRIS                     ###}
{###                                                              ###}
{###  Rubens Takiguti Ribeiro                                     ###}
{###                                                              ###}
{###  13-14/12/2004                                               ###}
{###                                                              ###}
{####################################################################}

program tetris;

uses crt;

const
   LARG = 10; { largura da matriz }
   ALT  = 24; { altura da matriz }
   COMSOM = false;

   { 1 = azul     }
   { 2 = verde    }
   { 3 = celeste  }
   { 4 = vermelho }
   { 5 = roxo     }
   { 6 = laranja  }
   { 7 = branco   }
   { 8 = preto    }
   fundo1 = 7; { bordas }
   fundo2 = 8; { fundo }
   texto = 3;
   texto2 = 7;

   esquerda = $04B00; { seta esquerda }
   direita  = $04D00; { seta direita  }
   gira     = $04800; { seta cima     }
   baixo    = $05000; { seta baixo    }
   esc      = $1B;    { tecla esc     }

type
   arq_texto = text; { arquivo onde estão as peças }

   matriz = array[1..LARG,1..ALT] of word;

   tipo_posicao = record
      coord: array[1..4,1..4] of boolean; { matriz que define uma peça }
   end;

   tipo_peca = record
      posicao:array[1..4] of tipo_posicao; { vetor com as 4 possíveis posições }
      pos: word;  { posição em que a peça está no momento }
      cor: word;  { cor da peça }
      x: word;    { coordenada X da peça }
      y: word;    { coordenada Y da peça }
   end;

var
   velocidade:integer;             { velocidade do jogo }
   pontos,pontosaux:word;          { pontos do jogador }
   campo:matriz;                   { campo onde o jogo procede }
   x,y,x1,y1:word;                 { coordenadas auxiliares }
   num,num2,prox,prox2:word;       { variaveix auxiliares }
   desce,fim:boolean;              { pode descer / acabou o jogo }
   linha:boolean;                  { há linha preenchida }
   peca:array[1..7] of tipo_peca;  { vetor de peças }
   acumulado,                      { linhas acumuladas }
   max:word;                       { teclas precionadas por iteração }
   tecla:longint;                  { tecla precionada }

{ procedimento inicial }
procedure inicio;
var
   posicao:tipo_posicao; { variável auxiliar para leitura de uma posição }
   arq:arq_texto; { arquivo onde estão as definições das peças }
   cont,cont2,cont3,cont4:word; { contadores auxiliares }
   aux:String; { variável auxiliar para leitura de uma linha do arquivo }

{ procedimento para limpar a peça }
procedure zera;
var
   i,j:word;
begin
   for i := 1 to 4 do
      for j := 1 to 4 do
         posicao.coord[i,j] := false;
end;{zera}

begin
   { limpando todo o campo com a cor do fundo }
   for y := 1 to ALT do
      for x := 1 to LARG do
         campo[x,y] := fundo2;

   assign(arq,'pecas.txt'); { abre o arquivo para ler as peças }
   reset(arq); { inicia o arquivo }
   for cont := 1 to 7 do { 7 pecas }
   begin
      { lê a cor da peça }
      readln(arq,aux);
      peca[cont].cor := ord(aux[1]) - ord('0');

      { lê as 4 posições possíveis para a peça }
      for cont2 := 1 to 4 do
      begin

         { para cada unidade, armazena temporariamente em posicao }
         for cont3 := 1 to 4 do { 4 linhas por posicao}
         begin
            readln(arq,aux); { aux recebe a linha }
            for cont4 := 1 to 4 do { 4 caracteres por linha }
               posicao.coord[cont4,cont3] := ( aux[cont4] = '1' );
         end;

         { atribui a posição lida para o vetor de peças }
         peca[cont].posicao[cont2] := posicao;
      end;

   end;
   close(arq); { fecha o arquivo }

end;

{ realiza um som }
procedure som(qtd,frq,som:integer);
begin
   if COMSOM then
      while qtd > 0 do
      begin
         Sound(som); { executa o som }
         delay(frq); { aguarda um tempo em milisegundos }
         nosound;    { para o som }
         qtd := qtd-1;
      end;
end;

{ tela principal }
procedure tela_limpa;
var
   i:integer;
begin
   clrscr; { limpa a tela toda do jogo }
   textbackground(fundo1); { define a cor do fundo }

   { coloca o cursor na posição e imprime a estrutura da fase }
   {1} 
   gotoxy(23,1);
   write('                                                         ');
   {2}
   gotoxy(46,2);
   textbackground(fundo2);
   write(' T E T R I S ');
   textbackground(fundo1);
   {3}
   gotoxy(23,3);
   write('                                                         ');
   {4..24}
   for i := 1 to ALT do
   begin
      gotoxy(2,i);
      write(' ');   { faixa esquerda }
      gotoxy(23,i);
      write('  ');  { faixa central }
      gotoxy(79,i);
      write(' ');   { faixa direita }
   end;
   {25}
   gotoxy(2,25);
   write('                                                                              ');

   { define a cor do fundo e da letra }
   textbackground(fundo2);
   textcolor(texto);

   { escreve os textos nos locais específicos }
   gotoxy(30,12);
   write('Digite a velocidade desejada (0-9) ou [S]air');
   gotoxy(35,14);
   write('Velocidade [         ]');
   gotoxy(35,16);
   write('Pontos     [         ]');

   gotoxy(35,20);
   write('Jogo de Tetris desenvolvido por:');
   gotoxy(35,22);
   write('     Rubens Takiguti Ribeiro    ');

   textcolor(texto2);
end;

{ limpa o campo quando acaba o jogo }
procedure limpa_campo;
var
   x,y:integer;
begin

   { define a cor do fundo }
   textbackground(fundo2);
   for y := 1 to ALT do
   begin
      for x := 1 to LARG do
      begin
         gotoxy((2*x)+1,y);
         write('  ');
         delay(5);
         campo[x,y] := fundo2;
      end;
   end;
   gotoxy(1,1);
end;

{ imprime a próxima peça }
procedure imprime_proxima(num_peca,pos_peca:word);
var
   x,y:word; { contadores auxiliares }
begin
   for y:= 1 to 4 do
      for x := 1 to 4 do
      begin
         { local onde imprimirá o pedaço da peça ou vazio }
         gotoxy(42+(x*2),4+y);

         { define a cor do fundo de acordo com o formato da peça }
         if peca[num_peca].posicao[pos_peca].coord[x,y] then
            textbackground(peca[num_peca].cor)
         else
            textbackground(fundo2);

         { imprime a unidade da peça }
         write('  ');
      end;
end;

{ imprime novo valor dos pontos }
procedure imprime_pontos(pontos:integer);
begin
   { define a cor do texto }
   textcolor(texto2);

   { define a posição onde ficam os pontos e imprime branco }
   gotoxy(48,16);
   write('       ');

   { define a posição onde ficam os pontos e imprime os pontos }
   gotoxy(48,16);
   write(pontos);
end;

{ imprime nova velocidade do jogo }
procedure imprime_velocidade(velocidade:integer);
begin
   { define a cor do texto }
   textcolor(texto2);

   { define a posição onde fica a velocidade e imprime branco }
   gotoxy(48,14);
   write('       ');

   { define a posição onde fica a velocidade e imprime a velocidade }
   gotoxy(48,14);
   write(velocidade);
end;

{ ler velocidade desejada }
function ler_velocidade:boolean;
var
   vel:char; { caracter lido }
begin

   { define a cor do texto, a posição e imprime branco no campo velocidade }
   textcolor(texto2);
   gotoxy(48,14);
   write('       ');

   { define a posição para leitura do teclado }
   gotoxy(48,14);

   { lê o teclado enquanto não selecionar uma opção válida}
   repeat
      vel := readkey;
   until (( ord(vel) <= ord('9') ) and ( ord(vel) >= ord('0') ) or (upcase(vel)='S'));

   { se escolheu alguma velocidade }
   if upcase(vel) <> 'S' then
   begin
      velocidade := ord(vel) - ord('0'); { recebeu alguma velocidade }
      ler_velocidade := true;
   end

   { se escolheu a opção sair }
   else
      ler_velocidade := false;
end;

{ imprime uma peça na sua posição }
procedure imprimep(p:tipo_peca);
var x,y:word;
begin

   { define a cor da peça }
   textbackground(p.cor);

   { para cada unidade da peça }
   for y := 1 to 4 do
      for x := 1 to 4 do

         { se a peça possui a unidade }
         if p.posicao[p.pos].coord[x,y] then
         begin

            { posiciona o cursor }
            gotoxy(((p.x+x-1)*2)+1,p.y+y-1);

            { imprime a unidade da peça }
            write('  ');

         end;

   { define a cor de fundo como a original}
   textbackground(fundo2);

   { define a posição (1,1) }
   gotoxy(1,1);
end;

{ limpa uma peca de sua pocicao }
procedure limpap(p:tipo_peca);
var x,y:word;
begin

   { define a cor do fundo }
   textbackground(fundo2);

   { para cada unidade da peça }
   for y := 1 to 4 do
      for x := 1 to 4 do

         { se a peça possui a unidade }
         if p.posicao[p.pos].coord[x,y] then
         begin

            { posiciona o cursor }
            gotoxy(((p.x+x-1)*2)+1,p.y+y-1);

            { e imprime branco na unidade da peça }
            write('  ');
         end;
end;

{ move a peca atual para direita ou esquerda }
procedure mover(var p:tipo_peca;sentido:boolean);
var
   x,y,x1,y1:word;
   pode:boolean;   { verifica se pode mover para o lado desejado }
begin
   pode := true;
   if sentido then { direita }
   begin

      { para cada unidade da peça }
      for y := 1 to 4 do
         for x := 1 to 4 do
         begin
            x1 := p.x + x;
            y1 := p.y + y - 1;

            { se é uma unidade da peça }
            if ( p.posicao[p.pos].coord[x,y] ) then

               { se a unidade é maior que a largura do campo }
               if ( x1 > LARG ) then
                  pode := false
               { ou se já existe uma peça naquele local }
               else if ( campo[x1,y1] <> fundo2 ) then
                  pode := false;
         end;

      { se pode mover para direita, incremeta a coordenada x }
      if pode then
         inc(p.x);
   end
   else { esquerda }
   begin

      { para cada unidade da peça }
      for y := 1 to 4 do
         for x := 1 to 4 do
         begin
            x1 := p.x + x - 2;
            y1 := p.y + y - 1;

            { se é uma unidade da peça }
            if ( p.posicao[p.pos].coord[x,y] ) then

               { se a coordenada x é menor que 1 }
               if ( x1 < 1 ) then
                  pode := false
               { ou se existe uma peça naquele local }
               else if ( campo[x1,y1] <> fundo2 ) then
                  pode := false;
         end;

      { se pode mover para esquerda, decremeta a coordenada x }
      if pode then
         dec(p.x);
   end;
end;

{ gira uma peca }
procedure girar(var p:tipo_peca);
var
   x,y,aux:word;
   pode:boolean; { pode girar }
begin
   aux := p.pos + 1; { posição da peça caso ela gire }

   { se ultrapassou o número de possibilidades, volta para 1 }
   if aux = 5 then
      aux := 1;

   pode := true;

   { para cada unidade da peça girada }
   for y := 1 to 4 do
   begin
      for x := 1 to 4 do
      begin

         { se é uma unidade da peça girada }
         if ( p.posicao[aux].coord[x,y] ) then
         begin

            { se está dentro dos limites do campo }
            if ( p.x+x-1 > 0 ) and ( p.x+x-1 <= LARG ) and
               ( p.y+y-1 > 0 ) and ( p.y+y-1 <= ALT ) then
            begin

               { se existe uma peça naquele local }
               if ( campo[p.x+x-1,p.y+y-1] <> fundo2 ) then
                  pode := false;
            end
            { se não está dentro dos limites do campo }
            else
               pode := false;
         end;
      end;{for}
   end;{for}

   { se pode girar, então recebe a posição girada }
   if pode then
      p.pos := aux;

end;

{ descer a peça }
procedure descer(var p:tipo_peca);
var
   desce:boolean; { pode descer }
   x,y:word;
   baixo: array[1..4] of word; { vetor com as unidades mais baixas da peça }
begin
   desce:=true;

   { procurar pelas unidades mais baixas da peça }
   for x := 1 to 4 do
   begin

      { define como unidade mais baixa a coordenada 0 }
      baixo[x] := 0;
      y := 4;

      { enquanto não encontrar posição mais baixa }
      while ( baixo[x] = 0 ) and  ( y > 0 ) do
      begin

         { se é a posição mais baixa, defini-la }
         if p.posicao[p.pos].coord[x,y] then
            baixo[x] := y

         { se não é a posição mais baixa, testa próxima coordenada }
         else
            dec(y);
      end;
   end;

   { enquanto pode descer }
   while desce do
   begin

      { para cada unidade mais baixa }
      for x := 1 to 4 do

         { se tem unidade na coluna x }
         if baixo[x] > 0 then
            { se a unidade vai ultrapassar a altura ou já existe peça no local }
            if ( p.y+baixo[x] > ALT ) or ( campo[p.x+x-1,p.y+baixo[x]] <> fundo2 ) then
               desce := false;

      { se pode descer }
      if desce then
         inc(p.y);
   end;
end;

{ destroi uma linha preenchida }
procedure destroir(linha:word);
var
   fim:boolean; { realizou o shift das linhas acima }
   x:word;
begin

   { define a cor do fundo e a posição da linha }
   textbackground(fundo2);
   gotoxy(3,linha);

   { imprime branco e faz o som }
   write('                    ');
   som(50,10,450);

   fim:= false;

   { enquanto não chegar no topo ou ter acabado }
   while (linha > 1) and not fim do
   begin
      fim := true;

      { para cada coluna do campo }
      for x := 1 to LARG do
      begin

         { realiza o shift }
         campo[x,linha] := campo[x,linha-1];

         { se a linha superior possui uma unidade de peça }
         if campo[x,linha-1] <> fundo2 then
            fim := false; { então não chegou ao fim }

         { imprime branco na unidade da linha superior }
         textbackground(campo[x,linha-1]);
         gotoxy((x*2)+1,linha);
         write('  ');

      end; {for}

      { decrementa a linha }
      dec(linha);
   end; {while}

   { limpar a primeira linha do campo }
   for x := 1 to LARG do
      campo[x,1] := 0;

   { imprimir branco na primeira linha do campo }
   textbackground(fundo2);
   gotoxy(3,1);
   write('                    ');
end;

{ **************************************************************************** }
{                                 Jogo Principal                               }
{ **************************************************************************** }

begin

   { deixa o cursor invisível}
   cursoroff;

   { procedimento inicial }
   inicio;

   { limpa o campo }
   tela_limpa;

   max := 0;

   { deixa o cursor visível }
   cursoron;

   { enquanto o jogador escolher uma velocidade }
   while ler_velocidade do
   begin
      cursoroff;
      imprime_velocidade(velocidade);

      { zera os pontos e imprime na tela }
      pontos := 0;
      pontosaux := 0;
      imprime_pontos(0);

      fim := false;

      { define qual será a próxima peça e qual será a próxima posição }
      randomize;
      prox := random(7) + 1;
      randomize;
      prox2 := random(4) + 1;

      repeat { repetir enquanto não chegar ao fim }

      { atribui peça atual e posição atual }
      num := prox;
      num2 := prox2;

      { define qual será a próxima peça e qual será a próxima posição }
      randomize;
      prox := random(7) + 1;
      randomize;
      prox2 := random(4) + 1 ;

      { imprime a próxima peça }
      imprime_proxima(prox,prox2);

      { define os atributos da peça atual no topo }
      peca[num].pos := num2;
      peca[num].x := LARG div 2;
      peca[num].y := 1;

      { verifica se existe uma peça no topo }
      for y := 1 to 4 do
         for x := 1 to 4 do
            if ( ( peca[num].posicao[peca[num].pos].coord[x,y] ) and
                 ( campo[4+x,1+y] <> fundo2 ) ) then
               fim := true; { se existe, chegou ao fim }

      { se não chegou ao fim }
      if not fim then
      begin
   
         desce := true;

         { enquanto a peça pode descer }
         while desce do
         begin
            { imprime a peça na sua coordenada específica }
            imprimep(peca[num]);

            { se pressionou uma tecla }
            if keypressed and (max < 4) then
            begin

               { recebe a tecla pressionada }
               tecla := ord(readkey) shl 8;

               { conta mais uma ação }
               inc(max);

               { se pressionou esquerda }
               if tecla = esquerda then
               begin
                  limpap(peca[num]);      { limpa a peça       }
                  mover(peca[num],false); { move para esquerda }
                  imprimep(peca[num]);    { imprime a peça     }
               end

               { se pressionou direita }
               else if tecla = direita then
               begin
                  limpap(peca[num]);     { limpa a peça      }
                  mover(peca[num],true); { move para direita }
                  imprimep(peca[num]);   { imprime a peça    }
               end

               { se pressionou para cima }
               else if tecla = gira then
               begin
                  limpap(peca[num]);   { limpa a peça   }
                  girar(peca[num]);    { gira a peça    }
                  imprimep(peca[num]); { imprime a peça }
               end

               { se pressionou para baixo }
               else if tecla = baixo then
               begin
                  limpap(peca[num]);   { limpa a peça   }
                  descer(peca[num]);   { desce a peça   }
                  imprimep(peca[num]); { imprime a peça }
               end

               { se pressionou 's' }
               else if tecla = (ord('s') shl 8) then
               begin
                  fim := true;    { define o fim da jogada }
                  desce := false;
               end;
            end

            { se nao pressionou nenhuma tecla }
            else
            begin
               max := 0; { zera o número de ações }

               { para cada unidade da peça }
               for y := 1 to 4 do
                  for x := 1 to 4 do
                  begin
                     x1 := peca[num].x;
                     y1 := peca[num].y;

                     { se é uma unidade da peça e ... }
                     if ( ( peca[num].posicao[peca[num].pos].coord[x,y] ) and
                          { há peça no local ou chegou na base do campo }
                          ( (campo[x1+x-1,y1+y]<>fundo2)or(y1+y-1=ALT)   ) ) then
                        desce := false; { então não pode descer mais }
                  end;

               { se pode descer }
               if desce then
               begin
                  limpap(peca[num]);   { limpa a peça   }
                  inc(peca[num].y);    { incrementa y   }
                  imprimep(peca[num]); { imprime a peça }
               end

               { se não pode descer: chegou na base }
               else
               begin
                  som(20,1,100); { fazer som }

                  { para cada unidade da peça }
                  for y := 1 to 4 do
                     for x := 1 to 4 do
                     begin
                        x1 := peca[num].x;
                        y1 := peca[num].y;
                        { se é uma unidade da peça }
                        if (peca[num].posicao[peca[num].pos].coord[x,y]) then

                           { insere a peça no campo }
                           campo[x1+x-1,y1+y-1] := peca[num].cor;
                     end;

                  { zera pontos acumulados }
                  acumulado := 0;

                  y := ALT;

                  { enquanto não chega ao topo do campo }
                  while y > 1 do
                  begin

                     { supor que a linha esteja preenchida }
                     linha := true;
                     x := 1;
                     while ( x <= LARG ) and linha do
                     begin

                        { se a linha possui espaço vazio }
                        if campo[x,y] = fundo2 then
                           linha := false { desfaz suposição }
                        { senão, verifica próxima coluna }
                        else
                           inc(x);
                     end;

                     { se a linha está totalmente preenchida }
                     if linha then
                     begin
                        destroir(y); { destroi a linha }
                        y := 25; { volta para base do campo }
                        inc(acumulado); { incrementa pontos acumulados }
                     end;
                     dec(y); { decrementa a altura }
                  end;{while}

                  { se acumulou pontos }
                  if acumulado > 0 then
                  begin
                     { define nova pontuação e imprime }
                     pontos := pontos + (acumulado*100) + ((acumulado-1)*50);
                     imprime_pontos(pontos);

                     { acrescenta pontos realizados na fase }
                     pontosaux := pontosaux + (acumulado*100) + ((acumulado-1)*50);

                     { se passou de fase }
                     if ( pontosaux > 1000 ) then
                     begin

                        { tira mil pontos da pontuação da fase }
                        pontosaux := pontosaux - 1000;

                        { incrementa a velocidade do jogo e imprime }
                        inc(velocidade);
                        if velocidade > 9 then { se chegou a nove, volta pra zero }
                           velocidade := 0;
                        imprime_velocidade(velocidade);
                     end;
                  end;
   
               end;

               { espera um tempo proporcional a velocidade do jogo }
               delay(500 div (velocidade + 1));

            end;{else}

         end; {while}
      end;
      until (fim);

      { limpa o campo }
      limpa_campo;
      cursoron;
   end; { enquanto ler velocidade }
   clrscr;
end.
