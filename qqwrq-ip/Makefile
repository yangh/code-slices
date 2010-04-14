all: qqwrq-ip test

qqwrq-ip: clean
	g++ -o qqwrq-ip *.cpp

test:
	[ -f QQWry.dat ] || echo "Download IP data file 'QQWry.dat ' first"; exit
	./qqwrq-ip 211.136.115.41
	./qqwrq-ip --data-path . 211.137.170.19
	./qqwrq-ip --data-path /root/src/qqwrq-ip 211.137.170.19
	./qqwrq-ip 211.136.28.167 211.137.170.19 211.137.180.23 211.137.211.139
	./qqwrq-ip --verbose --data-path /root/src/qqwrq-ip 211.137.170.19

clean:
	rm -f qqwrq-ip

