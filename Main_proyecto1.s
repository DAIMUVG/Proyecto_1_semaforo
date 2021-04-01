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
    
  PSECT udata_bank0 ;common memory
    cont:	DS  2 ;2 byte apartado
    banderas:	DS  1
    display_var:    DS	7 ;7 byte apartado
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
	movf    display_var, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 0	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    display1:
	movf    display_var+1, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 1	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    display2:
	movf    display_var+2, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
	movwf   PORTC	    ;Despues de pasar display_var a w movemos w al puertoC
	bsf	PORTD, 2	    ;seteamos el pin del puerto D para controlar que display se mostrara
	goto    siguientedisplay
	
    display3:
	movf    display_var+3, w  ;La variable display tiene el valor que necesito ya modificado para hexadecimal
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
    bsf	    WPUB, 0 	    ;Activo las resistencias de los puertos que usare
    bsf	    WPUB, 1
    bsf	    WPUB, 2
    
    clrf    TRISC
    clrf    TRISD
    
    movlw   1000B
    movwf   TRISE
    
    banksel PORTA	;reiniciar los puertos
    clrf    PORTA
    clrf    PORTC
    clrf    PORTD
    call    config_reloj    ;Configuracion de reloj para darle un valor al oscilador
    call    config_tmr0	    ;Configuracion del timer 0
    ;call    config_tmr1	    ;configuracion del timer 1
    
    ;call    config_IE	    ;Configuracion de las interrupciones
;----------loop principal---------------------
 loop:
    NOP
    goto loop
    

;------------sub rutinas---------------------
  config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bcf	    IRCF2	;OSCCON configuración bit2 IRCF
    bsf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 250kHz
    return
 
 config_tmr0:
    banksel OPTION_REG	;Banco de registros asociadas al puerto A
    bcf	    T0CS	;reloj interno clock selection
    bcf	    PSA		;Prescaler 
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0		;PS = 111 Tiempo en ejecutar , 256
    
    Reiniciar_tmr0
    return
end


