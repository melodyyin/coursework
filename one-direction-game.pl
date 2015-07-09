
% EECS 395 Knowledge Representation Project
% Melody Yin, Spring 2015
%
%
%% The purpose of this project is to utilize the various Prolog concepts
%% learned in this quarter as well as the developer’s deep knowledge
%% of the four members of One Direction to create a game where the
%% player’s goal is to convince one of the members to date him/her in
%% the amount of time allocated. The idea is that the player cannot ask
%% out any of the members directly, and he/she must explore the
%% different settings to check if any members are there.
%
%	To setup, use
%	'setup(NAME)' and then enter
%	'start' to get information about yourself

setup(PlayerName) :-
	retractall(interest(_)),
	retractall(fact(_)),
	asserta(fact(name(PlayerName))),
	Attractiveness is random(10),
	asserta(fact(attractiveness(Attractiveness))),
	Money is random(1000),
	asserta(fact(money(Money))),
	Time is random(600),
	asserta(fact(time(Time))),
	write('what are your interests? '),
	readln(Ans),
	my_interests(Ans).

my_interests(Ans) :-
	nth0(0, Ans, RealAns), % bypassing reading in as a list
	assert(interest(RealAns)),
	write('another one? (y/n) '),
	readln(Response), % all in one word
	Response = [y],
	write('what is it? '),
	readln(New),
	my_interests(New).

start :- write('hi, '), fact(name(Name)), writeln(Name),
	write('your attractiveness score is: '), fact(attractiveness(Attractiveness)), writeln(Attractiveness),
	write('you have this much money to use: '), fact(money(Money)), writeln(Money),
	write('you have this much time: '), fact(time(Time)), writeln(Time),
	write('your interests are: '), forall(interest(X), (write(X), write(', '))), nl,
	write('FIND A ONE DIRECTION MEMBER TO DATE!!!').

% gym increases attractiveness and reduces time
goto(gym) :-
	writeln('you are at the gym'),
	fact(attractiveness(OldAttractiveness)),
	increase_attractiveness(1),
	reduce_time(+(*(OldAttractiveness, 2), 10)), % takes longer to become more attractive if ur already attractive
	resources_check.

% plasticsurgeon increases attractiveness and reduces time and money
goto(plasticsurgeon) :-
	writeln('you are at the plastic surgeon office'),
	increase_attractiveness(2),
	reduce_time(30),
	reduce_money(200),
	resources_check.

% rollingstonesconcert reduces time and money
% but harry's there!!!!!
goto(rollingstonesconcert) :-
	writeln('you are at the concert and you meet harry!'),
	reduce_time(30),
	reduce_money(100),

	writeln('do you ask him out? (y/n) '),
	get_char(Ans),
	Ans = 'y',
	askout(harry).

goto(rollingstonesconcert) :-
	writeln('you leave the concert'),
	resources_check.

% nandos reduces money and attractiveness
% but nialls's there!!!
goto(nandos) :-
	writeln('you are at nandos and you meet niall!'),
	reduce_time(10),
	reduce_attractiveness(1),

	writeln('do you ask him out? (y/n) '),
	get_char(Ans),
	Ans = 'y',
	askout(niall).

goto(nandos) :-
	writeln('you leave nandos'),
	resources_check.

% theclub reduces time and increases attractiveness
% but liam is there!!!
goto(theclub) :-
	writeln('you are at the club and you meet liam!'),
	reduce_time(30),
	increase_attractiveness(1),

	writeln('do you ask him out? (y/n) '),
	get_char(Ans),
	Ans = 'y',
	askout(liam).

goto(theclub) :-
	writeln('you leave the club'),
	resources_check.

% six flags reduces time and money
% but louis is there!!!
goto(sixflags) :-
	writeln('you are at sixflags and you meet louis!'),
	reduce_time(30),
	reduce_money(50),

	writeln('do you ask him out? (y/n) '),
	get_char(Ans),
	Ans = 'y',
	askout(louis).

% zoo reduces time and money
goto(zoo) :-
	writeln('you are at the zoo'),
	reduce_time(30),
	reduce_money(30),
	resources_check.

% england reduces time and money
goto(england) :-
	writeln('you are in england'),
	reduce_time(200),
	reduce_money(200),
	resources_check.

% musiclessons adds music interests
goto(musiclessons) :-
	writeln('you are taking music lessons'),
	reduce_time(100),
	reduce_money(150),
	add_interest(music),
	add_interest(guitar),
	resources_check.

% dancelessons adds dance interests
goto(dancelessons) :-
	writeln('you are taking dance lessons'),
	reduce_time(100),
	reduce_money(150),
	add_interest(dancing),
	resources_check.

% university adds 5 interests
goto(university) :-
	writeln('you are taking classes at a university'),
	reduce_time(400),
	reduce_money(500),
	add_interest(reading),
	add_interest(writing),
	add_interest(math),
	add_interest(compsci),
	add_interest(psych),
	resources_check.

% time, money, attractiveness and interests operations
reduce_time(Amt) :-
	fact(time(OldTime)),
	retract(fact(time(_))),
	NewTime	is -(OldTime, Amt),
	asserta(fact(time(NewTime))).

reduce_money(Amt) :-
	fact(money(OldMoney)),
	retract(fact(money(_))),
	NewMoney is -(OldMoney, Amt),
	asserta(fact(money(NewMoney))).

increase_attractiveness(Amt) :-
	fact(attractiveness(OldAttractiveness)),
	retract(fact(attractiveness(_))),
	NewAttractiveness is +(OldAttractiveness, Amt),
	asserta(fact(attractiveness(NewAttractiveness))).
reduce_attractiveness(Amt) :-
	fact(attractiveness(OldAttractiveness)),
	retract(fact(attractiveness(_))),
	NewAttractiveness is -(OldAttractiveness, Amt),
	asserta(fact(attractiveness(NewAttractiveness))).

add_interest(Interest) :-
	asserta(fact(interest(Interest))).

% asking people out
askout(harry) :-
	writeln('you have decided to ask out harry'),
	fact(attractiveness(Attractiveness)),
	Attractiveness > 8,
	get_interests(Interests),
	(memberchk('music', Interests) ; memberchk('poetry', Interests)),
	writeln('harry says yes!'),
	break.

askout(harry) :-
	writeln('harry says no'),
	resources_check.

askout(niall) :-
	writeln('you have decided to ask out niall'),
	fact(attractiveness(Attractiveness)),
	Attractiveness > 6,
	get_interests(Interests),
	(memberchk('food', Interests) ; memberchk('guitar', Interests) ; memberchk('sports', Interests)),
	writeln('niall says yes!'),
	break.
askout(niall) :-
	writeln('niall says no'),
	resources_check.

askout(liam) :-
	writeln('you have decided to ask out liam'),
	fact(attractiveness(Attractiveness)),
	Attractiveness > 8,
	get_interests(Interests),
	(memberchk('clubbing', Interests) ; memberchk('partying', Interests) ; memberchk('dancing', Interests)),
	writeln('liam says yes!'),
	break.
askout(liam) :-
	writeln('liam says no'),
	resources_check.

askout(louis) :-
	writeln('you have decided to ask out louis'),
	fact(attractiveness(Attractiveness)),
	Attractiveness > 4,
	get_interests(Interests),
	length(Interests, N),
	N > 5,
	writeln('louis says yes!'),
	break.
askout(louis) :-
	writeln('louis says no'),
	resources_check.

% etc
get_interests(Interests) :-
	findall(X, interest(X), Interests).

resources_check :-
	fact(time(Seconds)),
	fact(money(Money)),
	Seconds > 0,
	Money > 0,
	writeln('all good on time and money!').

resources_check :-
	writeln('you are out of resources!'),
	break.
