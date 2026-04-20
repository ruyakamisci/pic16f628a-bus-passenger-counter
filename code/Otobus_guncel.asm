        LIST    P=16F628A
        #include <P16F628A.INC>

;--------------------------------------------------
; CONFIG
;--------------------------------------------------
        __CONFIG _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _LVP_OFF & _MCLRE_OFF & _BODEN_OFF

;--------------------------------------------------
; RAM TANIMLARI
;--------------------------------------------------
        CBLOCK  0x20
            SAYI        ; yolcu sayisi
            GECICI
            ONLAR
            BIRLER
            D1
            D2
        ENDC

;--------------------------------------------------
; RESET VEKTORU
;--------------------------------------------------
        ORG     0x0000
        GOTO    BASLA

;--------------------------------------------------
; ANA PROGRAM
;--------------------------------------------------
BASLA
        ; Comparator kapat
        MOVLW   0x07
        MOVWF   CMCON

        ; Bank1
        BSF     STATUS, RP0

        ; TRISA
        ; RA0 = birler latch  -> output
        ; RA1 = onlar latch   -> output
        ; RA2 = DOLU led      -> output
        ; digerleri input
        MOVLW   B'11111000'
        MOVWF   TRISA

        ; TRISB
        ; RB0-RB3 = BCD output
        ; RB4 = binis butonu input
        ; RB5 = inis butonu input
        ; RB6-RB7 input
        MOVLW   B'11110000'
        MOVWF   TRISB

        ; PORTB pull-up aktif
        MOVLW   B'00000000'
        MOVWF   OPTION_REG

        ; Bank0
        BCF     STATUS, RP0

        CLRF    PORTA
        CLRF    PORTB
        CLRF    SAYI

        CALL    GOSTER

ANA_DONGU

;---------------------------
; BINIS BUTONU (RB4)
;---------------------------
        BTFSC   PORTB, 4      ; 1 ise basilmamis
        GOTO    INIS_KONTROL  ; 0 ise basilmis olacak

        CALL    DELAY
        BTFSC   PORTB, 4
        GOTO    INIS_KONTROL

        ; Sayi 100 ise art?rma
        MOVF    SAYI, W
        XORLW   D'100'
        BTFSC   STATUS, Z
        GOTO    BINDEN_SONRA

        INCF    SAYI, F
        CALL    GOSTER

BINDEN_SONRA
        ; Buton b?rak?lana kadar bekle
BEKLE_BIRAK_BIN
        BTFSS   PORTB, 4
        GOTO    BEKLE_BIRAK_BIN
        CALL    DELAY

;---------------------------
; INIS BUTONU (RB5)
;---------------------------
INIS_KONTROL
        BTFSC   PORTB, 5
        GOTO    ANA_DONGU

        CALL    DELAY
        BTFSC   PORTB, 5
        GOTO    ANA_DONGU

        ; Sayi 0 ise azaltma
        MOVF    SAYI, F
        BTFSC   STATUS, Z
        GOTO    INISTEN_SONRA

        DECF    SAYI, F
        CALL    GOSTER

INISTEN_SONRA
        ; Buton birakilana kadar bekle
BEKLE_BIRAK_IN
        BTFSS   PORTB, 5
        GOTO    BEKLE_BIRAK_IN
        CALL    DELAY

        GOTO    ANA_DONGU

;--------------------------------------------------
; GOSTER
; 0-99 arasi sayiyi iki displayde gosterir
; 100 olursa DOLU cikisini yakar
; ve displaye 00 yollar
;--------------------------------------------------
GOSTER
        ; önce DOLU kontrolü
        MOVF    SAYI, W
        XORLW   D'100'
        BTFSS   STATUS, Z
        GOTO    NORMAL_GOSTER

        ; 100 ise DOLU aktif
        BSF     PORTA, 2

        ; 00 goster
        CLRF    GECICI
        CLRF    ONLAR
        CLRF    BIRLER

        MOVF    BIRLER, W
        CALL    BCD_YAZ
        CALL    LATCH_BIRLER

        MOVF    ONLAR, W
        CALL    BCD_YAZ
        CALL    LATCH_ONLAR
        RETURN

NORMAL_GOSTER
        ; DOLU kapat
        BCF     PORTA, 2

        ; GECICI = SAYI
        MOVF    SAYI, W
        MOVWF   GECICI
        CLRF    ONLAR

ONLAR_HESAPLA
        MOVLW   D'10'
        SUBWF   GECICI, W     ; W = GECICI - 10
        BTFSS   STATUS, C     ; borrow varsa GECICI < 10
        GOTO    HESAP_BITTI

        MOVLW   D'10'
        SUBWF   GECICI, F     ; GECICI = GECICI - 10
        INCF    ONLAR, F
        GOTO    ONLAR_HESAPLA

HESAP_BITTI
        MOVF    GECICI, W
        MOVWF   BIRLER

        ; Birler displaye yaz
        MOVF    BIRLER, W
        CALL    BCD_YAZ
        CALL    LATCH_BIRLER

        ; Onlar displaye yaz
        MOVF    ONLAR, W
        CALL    BCD_YAZ
        CALL    LATCH_ONLAR

        RETURN

;--------------------------------------------------
; BCD_YAZ
; W'deki 0-9 de?erini PORTB'nin alt 4 bitine yazar
;--------------------------------------------------
BCD_YAZ
        ANDLW   0x0F
        MOVWF   PORTB
        RETURN

;--------------------------------------------------
; LATCH_BIRLER
; RA0 pulse
;--------------------------------------------------
LATCH_BIRLER
        BSF     PORTA, 0
        NOP
        BCF     PORTA, 0
        RETURN

;--------------------------------------------------
; LATCH_ONLAR
; RA1 pulse
;--------------------------------------------------
LATCH_ONLAR
        BSF     PORTA, 1
        NOP
        BCF     PORTA, 1
        RETURN

;--------------------------------------------------
; DELAY
; buton siçramasini azaltmak için basit gecikme
;--------------------------------------------------
DELAY
        MOVLW   D'100'
        MOVWF   D1
DLY1
        MOVLW   D'200'
        MOVWF   D2
DLY2
        DECFSZ  D2, F
        GOTO    DLY2
        DECFSZ  D1, F
        GOTO    DLY1
        RETURN

        END


