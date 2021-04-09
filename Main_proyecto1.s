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

 MODO	EQU 0
 INC	EQU 1
 DECRE	EQU 2
	
reiniciar_Tmr0 macro	//macro
    banksel TMR0	//Banco de TMR0
    movlw   25
    ;movf    T0_Actual, W
    movwf   TMR0        
    bcf	    T0IF	//Limpiar bandera de overflow para reinicio 
    endm
reiniciar_Tmr1 macro	//macro reiniciar Tmr1
    movlw   0x0B	//1 segundo
    movwf   TMR1H	//Asignar valor a TMR1H
    movlw   0xDC
    movwf   TMR1L	//Asignar valor a TMR1L
    bcf	    TMR1IF	//Limpiar bandera de carry/interrupción de Tmr1
    endm
reiniciar_tmr2 macro	//Macro reinicio Tmr2
    banksel PR2		//250ms
    movlw   244		//Mover valor a PR2
    movwf   PR2		
    
    banksel T2CON
    clrf    TMR2	//Limpiar registro TMR2
    bcf	    TMR2IF	//Limpiar bandera para reinicio 
    endm
    
  PSECT udata_bank0 ;common memory
    ;1 byte apartado
    banderas:	  DS 1
    estado:	  DS 1
    parpadeo:	  DS 1
    sem_1:	  DS 1
    sem_2:        DS 1
    sem_3:        DS 1
    S1_temp:  DS 1
    S1:	  DS 1
    
    S2_temp:     DS 1
    S2:		 DS 1
    
    S3_temp:     DS 1
    SE3:	  DS 1
    v1:		  DS 1
    decena:	  DS 2
    unidad:	  DS 2  
    valor:	  DS 1
    v2:		  DS  1
    decena2:	  DS  2
    unidad2:	  DS  2  
    v3:		  DS  1
    decena3:	  DS  2
    unidad3:	  DS  2     
    v4:		  DS  1
    decena4:	  DS  2
    unidad4:	  DS  2 
    
  PSECT udata_shr ;common memory
    w_temp:	DS  1;1 byte apartado
    STATUS_TEMP:DS  1;1 byte
    PCLATH_TEMP:    DS	1
  
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
    movf    PCLATH, w
    movwf   PCLATH_TEMP	    ;Para que no afecte el PCLATH que usamos para el manejo de los displays
  isr:
    btfsc   RBIF
    call    IOCB_interrupt  ;Rutina de interrupcion del Modo
    
    btfsc   T0IF
    call    TMR0_interrupt  ;Rutina de interrupcion del timer 0
    
    btfsc   TMR2IF
    call    TMR2_interrupt  ;Rutina de interrupcion del timer 2
  pop:
    movf    PCLATH_TEMP, W
    movwf   PCLATH
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   w_temp, F
    swapf   w_temp, W
    retfie
;---------SubrutinasInterrupción-----------
TMR0_interrupt:
    reiniciar_Tmr0	;2 ms
    Bcf	    STATUS, 0
    clrf    PORTD 
    btfsc   banderas, 0	      ;Revisar bit 0 de banderas
    goto    display0	      ;Llamar a subrutina de displayunidad	    ;
    btfsc   banderas, 1	      ;Revisar bit 1 de banderas
    goto    display1          ;Llamar a subrutina de displaydecena
    btfsc   banderas, 2	      ;Revisar bit 2 de banderas
    goto    display2	      ;Llamar a subrutina de displaydecena
    btfsc   banderas, 3	      ;Revisar bit 3 de banderas
    goto    display3	      ;Llamar a subrutina de displaydecena
    btfsc   banderas, 4	      ;Revisar bit 4 de banderas
    goto    display4	      ;Llamar a subrutina de displaydecena
    btfsc   banderas, 5	      ;Revisar bit 5 de banderas
    goto    display5	      ;Llamar a subrutina de displaydecena
    btfsc   banderas, 6	      ;Revisar bit 6 de banderas
    goto    display6	      ;Llamar a subrutina de displaydecena
    btfsc   banderas, 7	      ;Revisar bit 7 de banderas
    goto    display7	      ;Llamar a subrutina de displaydecena
    movlw   00000001B
    movwf   banderas

Control_Luces:    
    movlw   4		    ;Parpadeo y luz amarilla semaforo 3
    subwf   sem_3, 0	    ;se le resta un valor de 4 a la variable sem_3
    btfss   STATUS, 0	    ;Evalua si un carry
    goto    amarillo3	    ;Vamos a la rutina amarillo
    movlw   7		    ;luz parpadeante del semaforo 3
    subwf   sem_3, 0	    ;se le resta un valor de 7 a la variable sem_3
    btfss   STATUS, 0	    ;Evalua si un carry
    goto    Parpadeo3	    ;Vamos de parpadeo
    
    call    tit2	    ;Hicimos una ruina de luces porque el programa no lo aceptaba solo asi
    
    movlw   4		    ;Parpadeo y luz amarilla semaforo 1
    subwf   sem_1, 0	
    btfss   STATUS, 0
    goto    amarillo1
    movlw   7
    subwf   sem_1, 0
    btfss   STATUS, 0
    goto    Parpadeo1
    return

tit2:			    ;Parpadeo y luz amarilla semaforo 2
    movlw   4
    subwf   sem_2, 0	;Guarda en w
    btfss   STATUS, 0
    GOTO    amarillo2
    movlw   7
    subwf   sem_2, 0
    btfss   STATUS, 0
    GOTO    Parpadeo2
    return
    
Parpadeo1:		;Rutina para controlar el parpadeo de la led verde
    btfss   parpadeo, 0	;revisamos el valor del parpadeo
    goto    apagardisp	;vamos a la rutina de apagar el display
    bsf     PORTA, 2	;Se va encendiendo la led verde
    return
    
Parpadeo2:
    btfss   parpadeo,0
    goto    apagardisp 
    bsf     PORTA,5
    return
Parpadeo3:
    btfss   parpadeo,0
    goto    apagardisp 
    bsf     PORTE, 2	;Se va encendiendo la led verde
    bcf	    PORTA, 5	;Apagamos la led verde del semaforo 2
    return
    
apagardisp:
    bcf     PORTA, 2	;Apagamos la led verde del semaforo 1
    bcf	    PORTA, 5	;Apagamos la led verde del semaforo 2
    bcf	    PORTE, 2	;Apagamos la led verde del semaforo 3
    return

amarillo1:		;Rutina de interrupcion de la led amarilla
    bcf	    PORTA, 0	;Apagamos la led roja
    bsf	    PORTA, 1	;Encendemos la led amarilla
    bcf	    PORTA, 2	;Apagamos la led roja
    movlw   0		;Parpadeo semaforo 1
    subwf   sem_1, 0	;Restamos el valor de w a sem_1
    btfsc   STATUS, 2	;Revisamos la bandera de Zero Bit
    goto    rojo1	;Vamos a la rutina de interrupcion de rojo
    return
rojo1:
    bcf	    PORTA, 1	;Apagamos la led amarilla
    bsf	    PORTA, 0	;Encendemos la led roja
    return   
amarillo2:
    bcf	    PORTA, 3
    bsf	    PORTA, 4
    bcf	    PORTA, 5
    movlw   0		;Parpadeo semaforo 2
    subwf   sem_2, 0	;Guarda en w
    btfsc   STATUS, 2
    goto    rojo2
    return
rojo2:
    bcf	    PORTA, 4
    bsf	    PORTA, 3
    return      
amarillo3:
    bcf	    PORTA, 5
    bcf	    PORTE, 2
    bsf	    PORTE, 1
    bcf	    PORTE, 0
    movlw   0		;Parpadeo semaforo 3
    subwf   sem_3, 0	;Guarda en w
    btfsc   STATUS, 2
    goto    rojo3
    return
rojo3:
    bcf	    PORTE, 2
    bcf	    PORTE, 1
    return      
   
display0:		;Rutina de los controles de los displays 
    movlw   00000010B	;Cambio de el valor de la variable bandera manualmente
    movwf   banderas	
    movf    unidad2+1,w ;Mando la variable unidad2+1 al puerto C	    
    movwf   PORTC
    bsf	    PORTD, 7	;Enciendo el bit del puerto D que controla el display
    goto    Control_Luces ;Vamos a la rutina control de luces
display1:
    movlw   00000100B
    movwf   banderas
    movf    decena2+1, w	    
    movwf   PORTC	    
    bsf	    PORTD, 6	    
    goto    Control_Luces
display2:
    movlw   00001000B
    movwf   banderas
    movf    decena+1, w	    
    movwf   PORTC	    
    bsf	    PORTD, 0	    
    goto    Control_Luces	
display3:
    movlw   00010000B
    movwf   banderas  
    movf    unidad+1, w	    
    movwf   PORTC	    
    bsf	    PORTD, 1	    
    goto    Control_Luces	
    
display4:
    movlw   00100000B
    movwf   banderas
    movf    unidad3+1, w	    
    movwf   PORTC	    
    bsf	    PORTD, 3	     
    goto    Control_Luces
display5:
    movlw   01000000B
    movwf   banderas
    movf    decena3+1, w	    
    movwf   PORTC	    
    bsf	    PORTD, 2	     
    goto    Control_Luces    
    
display6:
    movlw   10000000B
    movwf   banderas
    movf    unidad4+1, w	    
    movwf   PORTC	    
    bsf	    PORTD, 5	 
    
    goto    Control_Luces
display7:
    movlw   00000001B
    movwf   banderas
    movf    decena4+1, w	   
    movwf   PORTC	    
    bsf	    PORTD, 4	     
    movlw   0x00
    movwf   banderas	    
    goto    Control_Luces    
        
;-----------------------Interrupcion del puerto B-------------------------------
IOCB_interrupt:		    ;Rutina de interrupcion de los botones
    movf    estado, W	    ;Movemos estado a w
    clrf    PCLATH	    ;Limpiamos el PCLATH que sustituimos para las interrupciones
    andlw   0x07	    ;Acortamos la variable estado
    addwf   PCL		    ;me ayuda a ver que linea es el valor que esta buscando
    goto    I_estado0	    ;Vamos a la rutina de I_estado0
    goto    I_estado1
    goto    I_estado2
    goto    I_estado3; 0
    goto    I_estado4
    goto    Salida
    goto    Salida
 
I_estado0:		    ;Estado de interrupcion I_estado0
    banksel PORTB
    bsf     PORTA, 2	    ;Encendemos la led verde le semaforo 1
    btfsc   PORTB, MODO	    ;Revisamos el estado del boton MODO
    goto    Salida	    ;Si no esta presionado nos vamos a la rutina salida
    incf    estado	    ;Si esta presionado incrementamos la variable estado
    movf    S1, W	    ;Movemos el valor de S1 a w
    movwf   S1_temp	    ;Movemos w a S1_temp
    movf    S2, w
    movwf   S2_temp
    movf    SE3, w
    movwf   S3_temp
    goto    Salida	    ;Nos movemos a la rutina de salida
 
 I_estado1:		    ;Configuración semaforo 1
    btfss   PORTB, INC	    ;Revisamos el estado del boton INC
    incf    S1_temp, 1	    ;Si esta presionado incrementa S1_temp 
    movlw   21		 
    subwf   S1_temp, 0	    ;Se le resta 21 a la variable S1_temp
    btfsc   STATUS, 2	    ;Se revisa el estado de la bandera Zero Bit
    goto    min		    ;Si la badera es 1 vamos a la rutina min
    
    btfss   PORTB, DECRE    ;si la bancera es 0 revisamos el estado del boton DECRE
    decf    S1_temp, 1	    ;Si esta presionado decrementa S1_temp
    movlw   9
    subwf   S1_temp, 0	    ;Se le resta 9 a la variable S1_temp
    btfsc   STATUS, 2	    ;Se revisa el estado de la bandera Zero Bit
    goto    max		    ;Si la badera es 1 vamos a la rutina max
    
    btfss   PORTB, MODO	    ;Revisamos el esado del boton MODO
    incf    estado	    ;Si se presiona incrementamos el estado
    goto    Salida	    ;Si no se preciosa no lleva a la rutina Salida
 I_estado2:		    ;Configuración semaforo 2
    btfss   PORTB, INC
    incf    S2_temp, 1	    ;se guarda en mismo registro 
    movlw   21
    subwf   S2_temp, 0
    btfsc   STATUS, 2
    goto    min2
    
    btfss   PORTB, DECRE
    decf    S2_temp, 1
    movlw   9
    subwf   S2_temp, 0
    btfsc   STATUS, 2
    goto    max2
    
    btfss   PORTB, MODO
    incf    estado
    goto    Salida
 I_estado3:		    ;Configuración semaforo 3
    btfss   PORTB, INC
    incf    S3_temp, 1	    ;se guarda en mismo registro 
    movlw   21
    subwf   S3_temp, 0
    btfsc   STATUS, 2
    goto    min3
    
    btfss   PORTB, DECRE
    decf    S3_temp, 1
    movlw   9
    subwf   S3_temp, 0
    btfsc   STATUS, 2
    goto    max3
    
    btfss   PORTB, MODO
    incf    estado
    goto    Salida
 I_estado4:		    ;Rutina para aceptar o declinar los cambios
    btfss   PORTB, MODO	    ;verificamos si el boton de modo se presiona
    goto    prin_estado	    ;si se presiona se va a la rutina de principio de estado
    btfss   PORTB, DECRE    ;revisamos si el boton DECRE esta presionado
    clrf    estado	    ;si se presiona limpiamos la variable estado y se cancelan los cambios
    btfsc   PORTB, INC	    ;revisamos si el boton INC esta presionado
    goto    Salida	     ;si no se presiona nos vamos constantemente a la rutina Salida
    
    movf    S1_temp, W	    ;Pasamos el valor de la variable temporal a W
    movwf   S1		    ;El valor de W se lo pasamos a la variable S1 oficial
    movf    S1, W
    movwf   sem_1	    ;Pasamos el valor de S1 a sem_1 que es el que nos servira en el semaforo
	
    movf    S2_temp, W
    movwf   S2
    movf    S2, W
    movwf   sem_2  
    
    movf    S3_temp, W
    movwf   SE3
    movf    SE3, W
    movwf   sem_3
    clrf    estado	;limpiamos la varibale de estado
    clrf    PORTA	;le damos valores inciales a las luces del semaforo
    bsf     PORTA,3	
    bsf     PORTE,0
    
Salida:			;Rutina de Salida
    bcf	    RBIF	;Limpiamos la bandera 
    return
    
prin_estado:		;Rutina de principio de estado
    movlw   0x00	
    movwf   estado	;Dejamos en cero la variable de estado
    goto    Salida	;Vamos a la rutina de Salida
;-------------------Limites----------------------------------------------------
min:			;Rutina de valor minimo
    movlw   10		
    movwf   S1_temp	;Asignamos el valor de 10 a S1_temp
    bcf	    RBIF	;Limpiamos la bandera
    return
    
max:			;Rutina de valor maximo
    movlw   20		
    movwf   S1_temp	;Asiganmos el valor de 20 a S1_temp
    bcf	    RBIF	;Limpiamos la bandera
    return
    
min2:
    movlw   10
    movwf   S2_temp
    bcf	    RBIF
    return
    
max2:
    movlw   20
    movwf   S2_temp
    bcf	    RBIF
    return
    
min3:
    movlw   10
    movwf   S3_temp
    bcf	    RBIF
    return
    
max3:
    movlw   20
    movwf   S3_temp
    bcf	    RBIF
    return
;------------------------Interrupcion del puerto 2------------------------------    
TMR2_interrupt:		;Rutina de tiempo del parpadeo
    bcf    TMR2IF	;Apgamos la bandera del timer 2
    incf   parpadeo	;Incrementamos la variable parpadeo
    return
    
  PSECT code, delta=2, abs
  ORG 180h	;Posición para el código
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
    retlw 01110111B          ; A
    retlw 01111100B          ; b
    retlw 00111001B          ; C
    retlw 01011110B          ; d
    retlw 01111001B          ; E
    retlw 01110001B          ; F
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
    bsf	    WPUB, MODO 	    ;Activo las resistencias de los puertos que usare
    bsf	    WPUB, INC
    bsf	    WPUB, DECRE
    
    clrf    TRISC
    clrf    TRISD
    clrf    TRISE
    
    banksel PORTA       ;reiniciar los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
    call    config_reloj    ;Llamamos a la rutina de configuración del reloj
    call    config_IO	    ;Configuracion de interrupcion del puerto B
    call    config_tmr0	    ;Configuración del timer0
    call    config_tmr1	    ;Configuración del timer1
    call    config_tmr2	    ;Configuración del timer2
    call    config_IE	    ;Configuración de las interrupciones

;--------------Actualizacion de valores-----------------------------------------        
    banksel PORTA 
    clrf    estado
    movlw   0x0E
    movwf   S1
    movf    S1, W
    movwf   sem_1
    movlw   0x0A
    movwf   S2
    movf    S2, W
    movwf   sem_2
    movlw   0x0A
    movwf   SE3
    movf    SE3, w
    movwf   sem_3
    bsf	    PORTA, 2
    bcf	    PORTA, 1
    bsf	    PORTA, 3
    bsf	    PORTE, 0

    
;----------loop principal---------------------
 loop:
    btfss   TMR1IF	    ;Funcionamiento semaforo
    goto    $-1		    ;Si la bandera esta abajo regresa a evaluarse
    reiniciar_Tmr1	    ;Si la bandera esta arriba reiniciamos el timer 1
    call    inicio1	    ;vamos a la rutina de inicio
    
    movf    sem_1, w	    ;Displays semaforo1
    movwf   v1		    ;Pasamos el valor de sem_1 a la variable v1
    call    Decenas	    ;Subrutina para contador decimal
    call    dispdecimal	    ;Llamamos a la rutina de dispdecimal
    
    movf    sem_2, w	    ;Displays semaforo2    
    movwf   v3
    call    Decenas3	
    call    dispdecimal3
    
    movf    sem_3, w	    ;Displays semaforo1    
    movwf   v4
    call    Decenas4	
    call    dispdecimal4
       
    bcf	    GIE		    ;Limpiamos la bandera de las interrupciones globales
    movf    estado, W	    ;Paso el valor de estado a w
    clrf    PCLATH	    ;limpiamos PCLATH
    bsf	    PCLATH, 0	    
    andlw   0x07	    ;Acosrtamos los bits de la variable estado
    addwf   PCL		    ;PCL no ayudara a recorre
    goto    estado0	    ;vamos a la rutina de estado 0
    goto    estado1
    goto    estado2
    goto    estado3
    goto    estado4
    goto    loop
    goto    loop
    
 estado0:		   ;Rutina de interrupcion de estado 0
    bsf	    GIE		   ;Encendemos la bandera de interrupcion globales
    clrf    valor	   ;Limpiamos la variable de valor
    bcf	    PORTB, 3	   ;vamos encendiendo las leds que indiquen el semaforo a modificar
    bcf	    PORTB, 4
    bcf	    PORTB, 5   
    goto    loop    ;loop forever
 estado1:
    bsf	    GIE
    movf    S1_temp, w	 
    movwf   v2		;Pasamos el valor de la variable S1_temp a v2
    call    Decenas1	;Subrutina de división para contador DECIMAL 
    call    dispdecimal1 ;Rutina para preparar variables para los displays
    bsf	    PORTB, 3
    bcf	    PORTB, 4
    bcf	    PORTB, 5
    goto    loop
 estado2:
    bsf	    GIE
    movf    S2_temp, w
    movwf   v2
    call    Decenas1	//Subrutina de división para contador DECIMAL 
    call    dispdecimal1
    bcf	    PORTB, 3
    bsf	    PORTB, 4
    bcf	    PORTB, 5
    goto    loop
 estado3:
    bsf	    GIE
    movf    S3_temp, w
    movwf   v2
    call    Decenas1	//Subrutina de división para contador DECIMAL 
    call    dispdecimal1
    bcf	    PORTB, 3
    bcf	    PORTB, 4
    bsf	    PORTB, 5
    goto    loop
 estado4:
    bsf	    GIE
    bsf	    PORTB, 3
    bsf	    PORTB, 4
    bcf	    PORTB, 5
    goto    loop
;------------sub rutinas---------------------    
inicio1: 
    
    movlw   0x00
    subwf   sem_1
    btfsc   STATUS, 2
    goto    inicio2
    decf    sem_1
    return 
inicio2:
    bsf	    PORTA, 5	;verde semaforo 2
    bcf	    PORTA, 3	;Rojo Semaforo 2
    bsf	    PORTE, 0	;Rojo Semaforo 3
    clrf    sem_1  
    movlw   0x00
    subwf   sem_2
    btfsc   STATUS, 2
    goto    inicio3
    decf    sem_2
    return 
    
inicio3:
    bsf	    PORTE, 2
    bsf	    PORTA, 0
    bsf	    PORTA, 3
    bcf     PORTE, 0
    clrf    sem_2
    movlw   0x00
    subwf   sem_3  
    btfsc   STATUS, 2
    goto    asignarvalor
    decf    sem_3
    return 
    
asignarvalor:	;Rutina para asignar valores
    movf    S1, W   
    movwf   sem_1   ;Movemos el valor de S1 a sem_1
    movf    S2, W
    movwf   sem_2
    movf    SE3, W
    movwf   sem_3
    movlw   00001100B
    movwf   PORTA   ;encendemos el verde del S1 y el rojo del S2
    bsf	    PORTE, 0;Encendemos el rojo del S3
    return

;------------------DivisiónRutinaPrincipal-------------------
dispdecimal:
    movf    decena, w	
    call    Tabla   ;Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena+1	;Lo guardamos en variable decena+1
    movf    unidad, w
    call    Tabla   ;Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad+1	;Lo guardamos en variable unidad+1
    return
Decenas:
    clrf    decena	;Limpiamo variable decena
    movlw   00001010B	;Valor de 10 a w   
    subwf   v1,1	;Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	;Revisamo bit de carry Status
    goto    Unidades	;Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena, 1	;Incrementa variable decena 
    goto    $-5		;Ejecuta resta en decenas 
Unidades:
    clrf    unidad	;Limpiamos variable unidad
    movlw   00001010B	
    addwf   v1		;Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	;Valor de 1 a w
    subwf   v1,1	;Restamos f-w y guardamos en V1
    btfss   STATUS, 0	;Revisar bit carry de status
    return		;Return a donde fue llamado
    incf    unidad, 1	;Incrementar variable unidad
    goto    $-5		;Ejecutar de nuevo resta de unidad 
    
;---------------------------RutinaSemaforo1---------------------------
dispdecimal1:
    movf    decena2, w	
    call    Tabla   ;Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena2+1	;Lo guardamos en variable decena2+1
    movf    unidad2, w
    call    Tabla   ;Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad2+1	;Lo guardamos en variable unidad2+1
    return
Decenas1:
    clrf    decena2	;Limpiamo variable decena
    movlw   00001010B	;Valor de 10 a w   
    subwf   v2,1	;Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	;Revisamo bit de carry Status
    goto    Unidades1	;Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena2, 1	;Incrementa variable decena 
    goto    $-5		;Ejecuta resta en decenas 
Unidades1:
    clrf    unidad2	;Limpiamos variable unidad
    movlw   00001010B	
    addwf   v2		;Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	;Valor de 1 a w
    subwf   v2,1	;Restamos f-w y guardamos en V1
    btfss   STATUS, 0	;Revisar bit carry de status
    return		;Return a donde fue llamado
    incf    unidad2, 1	;Incrementar variable unidad
    goto    $-5		;Ejecutar de nuevo resta de unidad 
;------------------------------------------------------------------------------------
    
    
dispdecimal3:
    movf    decena3, w	
    call    Tabla   ;Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena3+1	;Lo guardamos en variable decena3+1
    movf    unidad3, w
    call    Tabla   ;Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad3+1	;Lo guardamos en variable unidad3+1
    return
Decenas3:
    clrf    decena3	;Limpiamo variable decena
    movlw   00001010B	;Valor de 10 a w   
    subwf   v3,1	;Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	;Revisamo bit de carry Status
    goto    Unidades3	;Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena3, 1	;Incrementa variable decena 
    goto    $-5		;Ejecuta resta en decenas 
Unidades3:
    clrf    unidad3	;Limpiamos variable unidad
    movlw   00001010B	
    addwf   v3		;Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	;Valor de 1 a w
    subwf   v3,1	;Restamos f-w y guardamos en V1
    btfss   STATUS, 0	;Revisar bit carry de status
    return		;Return a donde fue llamado
    incf    unidad3, 1	;Incrementar variable unidad
    goto    $-5		;Ejecutar de nuevo resta de unidad    
    
;--------------------------------------------------------------------------------
    
dispdecimal4:
    movf    decena4, w	
    call    Tabla   ;Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena4+1	;Lo guardamos en variable decena4+1
    movf    unidad4, w
    call    Tabla   ;Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad4+1	;Lo guardamos en variable unidad4+1
    return
Decenas4:
    clrf    decena4	;Limpiamo variable decena
    movlw   00001010B	;Valor de 10 a w   
    subwf   v4,1	;Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	;Revisamo bit de carry Status
    goto    Unidades4	;Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena4, 1	;Incrementa variable decena 
    goto    $-5		;Ejecuta resta en decenas 
Unidades4:
    clrf    unidad4	;Limpiamos variable unidad
    movlw   00001010B	
    addwf   v4		;Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	;Valor de 1 a w
    subwf   v4,1	;Restamos f-w y guardamos en V1
    btfss   STATUS, 0	;Revisar bit carry de status
    return		;Return a donde fue llamado
    incf    unidad4, 1	;Incrementar variable unidad
    goto    $-5		;Ejecutar de nuevo resta de unidad    
;-------------------------------------------------------------------------------    
config_IO:		;Rutina de configuracionde los botones
    banksel TRISA
    bsf	    IOCB, MODO
    bsf	    IOCB, INC
    bsf	    IOCB, DECRE
    
    banksel PORTA
    movf    PORTB, W	;Condición mismatch
    return
	
 config_tmr0:		;Configuración del timer 0
    banksel OPTION_REG  ;Banco de registros asociadas al puerto A
    bcf	    T0CS	; reloj interno clock selection
    bcf	    PSA		;Prescaler 
    bcf	    PS2
    bcf	    PS1
    bsf	    PS0		;PS = 111 Tiempo en ejecutar , 256
    
    reiniciar_Tmr0	;Macro reiniciar tmr0
    return
    
 config_tmr1:		;Configuración del timer 1
    banksel T1CON
    bcf	    TMR1GE	;tmr1 como contador
    bcf	    TMR1CS	;Seleccionar reloj interno (FOSC/4)
    bsf	    TMR1ON	;Encender Tmr1
    bcf	    T1OSCEN	;Oscilador LP apagado
    bsf	    T1CKPS1	;Preescaler 10 = 1:4
    bcf	    T1CKPS0 
    
    reiniciar_Tmr1	;Macro de reinicio de timer 0
    return
 

 config_tmr2:		;Configuración del timer 2
    banksel T2CON
    bsf	    T2CON, 7 
    bsf	    TMR2ON
    bsf	    TOUTPS3	;Postscaler 1:16
    bsf	    TOUTPS2
    bsf	    TOUTPS1
    bsf	    TOUTPS0
    bsf	    T2CKPS1	;Preescaler 1:16
    bsf	    T2CKPS0
    
    reiniciar_tmr2
    return
    
 config_reloj:		;Rutina de configuraciond del reloj
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuración bit2 IRCF
    bcf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 1Mhz
    return
    

config_IE:		;Configuración de las interrupciones
    BANKSEL PIE1
    bsf	    T0IE	;Habilitar bit de interrupción tmr0
    BSF     TMR2IE
    BANKSEL T1CON 
    bsf	    GIE		;Habilitar en general las interrupciones, Globales
    bsf	    RBIE	;Se encuentran en INTCON
    bcf	    RBIF	;Limpiamos bandera
    bcf	    T0IF	;Limpiamos bandera de overflow de tmr0
    BCF     TMR2IF
    return
    
 
 
end