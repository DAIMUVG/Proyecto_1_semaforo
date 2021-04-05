;Archivo:	Main_proyecto1.s
;dispositivo:	PIC16F887
;Autor:		Dylan Ixcayau
;Compilador:	pic-as (v2.31), MPLABX V5.45
;
;Programa:	Proyecto_semaforo
;Hardware:	Displays, leds y botones
;
;Creado:	23 mar, 2021
;Ultima modificacion:  
;-----------------------------------
PROCESSOR 16F887
#include <xc.inc>

; configuración word1
 CONFIG FOSC=INTRC_NOCLKOUT //Oscilador interno sin salidas
 CONFIG WDTE=OFF	    //WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON	    //PWRT enabled (espera de 72ms al iniciar
 CONFIG MCLRE=OFF	    //pin MCLR se utiliza como I/O
 CONFIG CP=OFF		    //sin protección de código
 CONFIG CPD=OFF		    //sin protección de datos
 
 CONFIG BOREN=OFF	    //sin reinicio cuando el voltaje baja de 4v
 CONFIG IESO=OFF	    //Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF	    //Cambio de reloj externo a interno en caso de falla
 CONFIG LVP=ON		    //Programación en bajo voltaje permitida
 
;configuración word2
  CONFIG WRT=OFF	//Protección de autoescritura 
  CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V 


  ;----------------------macros---------------------------------
  Reiniciar_tmr0 macro
    banksel TMR0	;reinicio del timer 0
    movlw   256
    movwf   TMR0
    bcf	    T0IF	;0.9 ms
    endm
  Reiniciar_tmr1 macro
    movlw   0x0B    ;Le asignamos un valor correspondiente al timer1 para 1 segundo  
    movwf   TMR1H
    movlw   0xDC
    movwf   TMR1L
    bcf	    TMR1IF  ;limpiamos la bandera del timer1
  endm
  
  Reiniciar_tmr2 macro
    Banksel PR2	    ;llamamos al banco donde esta ubicado PR2
    movlw   244	    ;le asignamos un valor al timer 2 segun su formula
    movwf   PR2	    
    
    
    banksel T2CON   
    clrf    TMR2    ;limpiamos el timer 2
    bcf	    TMR2IF  ;limpiamos la bandera del timer 2
  endm
  PSECT udata_bank0 ;common memory
    value_setup: DS  1 ;1 byte apartado
    banderas:	DS  1
    estado:	DS  1
    display_var:    DS	7 ;7 byte apartado
    timer0:	DS  1
    timer0_temp:    DS  1
    sem_1:	DS  1
    valor:	DS  1
    decena:	DS  4
    unidad:	DS  4
    v1:		DS  1
    v2:		DS  1
  PSECT udata_shr ;common memory
    w_temp:	DS  1;1 byte apartado
    STATUS_TEMP:DS  1;1 byte
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------
  ORG 00h	;posición 000h para el reset
  resetVec:
    PAGESEL main
    goto main
    
  PSECT intVect, class=CODE, abs, delta=2
  ;----------------------interripción reset------------------------
  ORG 04h	;posición 0004h para interr
  push:
    movf    w_temp
    swapf   STATUS, W
    movwf   STATUS_TEMP
  isr:
    btfsc   T0IF	    ;Si el timer0  levanta ninguna bandera de interrupcion
    call    TMR0_interrupt  ;Rutina de interrupcion del timer0
    
     btfsc   RBIF	    ;Si el puerto B levanta la banderas de interrupcion
     call    IOCB_interrupt  ;Rutina de interrupcion del puerto B
  pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   w_temp, F
    swapf   w_temp, W
    retfie
    
;----------------------Rutinas de interrupcion------------------------
   TMR0_interrupt:
	Reiniciar_tmr0
	bcf	STATUS, 0	    ;Dejo el STATUS 0 en un valor de 0
	clrf    PORTD		    ;Limpio el puerto D
	btfsc   banderas, 0	    ;Las banceras me ayudaran a hacer los saltos entre cada display
	goto    display0	    ;Si la variable vandera es 1 en la posicion 1 vamos a la rutina del display0
	btfsc   banderas, 1	    
	goto    display1
	btfsc   banderas, 2	    ;Las banceras me ayudaran a hacer los saltos entre cada display
	goto    display2	    ;Si la variable vandera es 1 en la posicion 1 vamos a la rutina del display0
	btfsc   banderas, 3	    
	goto    display3
	btfsc   banderas, 4	    ;Las banceras me ayudaran a hacer los saltos entre cada display
	goto    display4	    ;Si la variable vandera es 1 en la posicion 1 vamos a la rutina del display0
	btfsc   banderas, 5	    
	goto    display5
	btfsc   banderas, 6	    ;Las banceras me ayudaran a hacer los saltos entre cada display
	goto    display6	    ;Si la variable vandera es 1 en la posicion 1 vamos a la rutina del display0
	btfsc   banderas, 7	    
	goto    display7
	movlw   00000001B	    ;le agregamos un valor a la variable banderas
    siguientedisplay:
	RLF	    banderas, 1	    ;Me ayuda a cambiar la bandera e ir al siguiente display
	return
    
    display0:
	movf    decena+3, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 0	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    display1:
	movf    unidad+3, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 1	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    display2:
	movf    decena+1, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 2	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    display3:
	movf    unidad+1, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 3	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    display4:
	movf    display_var+4, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 4	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    display5:
	movf    display_var+5, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 5	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    display6:
	movf    display_var+6, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 6	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    display7:
	movf    display_var+7, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 7	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    IOCB_interrupt:
	movf    estado, W
	clrf    PCLATH		
	andlw   0x03
	addwf   PCL
	goto    estado0
	goto    estado1
	goto    estado2; 0
	
    estado0:
	 banksel PORTB
	btfsc   PORTB, 0
	goto    Salida
	incf    estado
	movf    timer0, W
	movwf   timer0_temp
	goto    Salida
	
    estado1:
	btfss   PORTB, 1
	incf    timer0_temp, 1   ;se guarda en mismo registro 
	movlw   21
	subwf   timer0_temp, 0
	btfsc   STATUS, 2
	goto    min

	btfss   PORTB, 2
	decf    timer0_temp, 1
	movlw   9
	subwf   timer0_temp, 0
	btfsc   STATUS, 2
	goto    max

	btfss   PORTB, 0
	incf    estado
	goto    Salida
	
    estado2:
	btfss   PORTB, 2
	clrf    estado
	btfsc   PORTB, 1
	goto    Salida
	movf    timer0_temp, W
	movwf   timer0
	movf    timer0, W
	movwf   sem_1
	clrf    estado
	
    Salida:
	bcf	    RBIF
	return
	
    min:
	movlw   10
	movwf   timer0_temp
	bcf	RBIF
	return
    max:
	movlw   20
	movwf   timer0_temp
	bcf	RBIF
	return
	
  PSECT code, delta=2, abs
  ORG 100h	;Posición para el código
 ;------------------ TABLA -----------------------
  Tabla:
    clrf  PCLATH
    bsf   PCLATH,0
    andlw 0x0F
    addwf PCL
    retlw 00111111B          ; 0
    retlw 00000110B          ; 1
    retlw 01011011B          ; 2
    retlw 01001111B          ; 3
    retlw 01100110B          ; 4
    retlw 01101101B          ; 5
    retlw 01111101B          ; 6
    retlw 00000111B          ; 7
    retlw 01111111B          ; 8
    retlw 01101111B          ; 9
 
  ;---------------configuración------------------------------
  main:
    banksel ANSEL	;configurar como digital
    clrf    ANSEL	
    clrf    ANSELH
    
    banksel TRISA	;configurar como salida los puertos seleccionados
    movlw   11000000B
    movwf   TRISA
    
    movlw   11000111B
    movwf   TRISB
    
    bcf    OPTION_REG, 7   ;Activo la opcion de las resistencias en el PUERTOB 
    bsf	    WPUB, 0 	    ;Activo las resistencias de los puertos que usare
    bsf	    WPUB, 1
    bsf	    WPUB, 2
    
    clrf    TRISC
    clrf    TRISD
    
    movlw   1000B
    movwf   TRISE
    
    banksel PORTA	;reiniciar los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    
    call    config_reloj    ;Configuracion de reloj para darle un valor al oscilador
    call    config_tmr0	    ;Configuracion del timer 0
    call    config_IO
    call    config_tmr1	    ;configuracion del timer 1
    call    config_IE	    ;Configuracion de las interrupciones
    
    movlw   0x0F
    movwf   timer0
    movf    timer0, w
    movwf   sem_1
    bsf	    PORTA, 0
    bcf	    PORTA, 1
;----------loop principal---------------------
 loop:
    btfss   TMR1IF
    goto    $-1
    Reiniciar_tmr1
    decf    sem_1, 1
    btfsc   STATUS, 2
    call    asignar_valor
    movlw   7
    subwf   sem_1, 0
    btfss   STATUS, 0
    call    amarillo1
    
    movf    sem_1, w
    movwf   v1
    call    Decenas
    call    dispdecimal
    
    bcf	    GIE
    movf    estado, w
    clrf    PCLATH
    bsf	    PCLATH, 0
    andlw   0x03
    addwf   PCL
    goto    estado_0
    goto    estado_1
    goto    estado_2
 estado_0:
    bsf	    GIE
    clrf    valor    
    bsf	    PORTB, 3
    bcf	    PORTB, 4
    bcf	    PORTB, 5
    goto    loop    ;loop forever
 estado_1:
    bsf	    GIE
    movf    timer0_temp, w
    movwf   v2
    call    Decenas1	//Subrutina de división para contador DECIMAL 
    call    dispdecimal1
    bcf	    PORTB, 3
    bsf	    PORTB, 4
    bcf	    PORTB, 5
    goto    loop
 estado_2:
    bsf	    GIE
    bcf	    PORTB, 3
    bcf	    PORTB, 4
    bsf	    PORTB, 5
    goto    loop
    
;------------sub rutinas---------------------
amarillo1:
    bcf	    PORTA, 0
    bsf	    PORTA, 1
    return
    
asignar_valor:
    bsf	    PORTA, 0
    bcf	    PORTA, 1
    movf    timer0, W
    movwf   sem_1
    return
;------------------DivisiónRutinaPrincipal-------------------
    
;-------------Subrutina para display modificacion--------
dispdecimal:
    movf    decena, w	
    call    Tabla        ;Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena+1	 ;Lo guardamos en variable decena1
    movf    unidad, w
    call    Tabla        ;Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad+1	 ;Lo guardamos en variable unidad1
    return
Decenas:
    clrf    decena	//Limpiamo variable decena
    movlw   00001010B	//Valor de 10 a w   
    subwf   v1,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    Unidades	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
Unidades:
    clrf    unidad	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   v1		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   v1,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad 
    
;---------------------------RutinaSemaforo1---------------------------
dispdecimal1:
    movf    decena+2, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena+3	//Lo guardamos en variable decena1
    movf    unidad+2, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad+3	//Lo guardamos en variable unidad1
    return

Decenas1:
    clrf    decena+2	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   v2		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   v2,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    Unidades1	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena+2, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
Unidades1:
    clrf    unidad+2	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   v2		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   v2,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad+2, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad

  config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuración bit2 IRCF
    bcf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 1MHz
    return
 
  config_tmr0:
    banksel OPTION_REG	;Banco de registros asociadas al puerto A
    bcf	    T0CS	;reloj interno clock selection
    bcf	    PSA		;Prescaler 
    bcf	    PS2
    bcf	    PS1
    bsf	    PS0		;PS = 111 Tiempo en ejecutar , 256
    
    Reiniciar_tmr0
    return
    
  config_tmr1:
    banksel T1CON 
    bcf	    TMR1GE  ;ponemos al timer en configuracion de siempre contando
    bsf	    T1CKPS1 ;Preescaler 1:2
    bcf	    T1CKPS0
    bcf	    T1OSCEN ;Reloj interno
    bcf	    TMR1CS   
    bsf	    TMR1ON  ;Encendemos el TMR1
    
    Reiniciar_tmr1
    return
    
  config_tmr2:
    banksel T2CON   ;llamamos al banco donde esta ubicado T2CON
    movlw   11111111B	;configuramos bit por bit el registro T2CON con lo que necesitamos
    movwf   T2CON	
    
    Reiniciar_tmr2
    return
    
  config_IE:	    
    banksel PIE1    ;llamamos al banco donde esta ubicado PIE
    ;bsf	    TMR1IE  ;habilitamos las interrupciones correspondientes
    ;bsf	    TMR2IE
    bsf	    T0IE
    banksel INTCON
    bsf	    RBIE	;Se encuentran en INTCON
    bcf	    RBIF	;Limpiamos bandera
    banksel T1CON
    bsf	    GIE	    ;Habilitar en general las interrupciones, Globales
    bsf	    PEIE    ;habilitamos las interrupciones de los perifericos
    ;bcf	    TMR1IF  
    ;bcf	    TMR2IF
    bcf	    T0IF	;Limpiamos bandera
    return
    
config_IO:
    banksel TRISA
    bsf	    IOCB, 0	;encendemos la interrupcion del puerto
    bsf	    IOCB, 1	;encendemos la interrupcion del puerto
    bsf	    IOCB, 2
    
    banksel PORTA
    movf    PORTB, W	;Condición mismatch
    bcf	    RBIF
    return    
end


