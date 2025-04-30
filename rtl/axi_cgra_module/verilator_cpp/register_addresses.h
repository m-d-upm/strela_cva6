// CSR addresses for use by a C program

#define CGRA_CTRL_A 0x00
    #define CGRA_CTRL_BIT_START_EXEC  0x1
    #define CGRA_CTRL_BIT_CLEAR       0x2
    #define CGRA_CTRL_BIT_LOAD_CONFIG 0x4
    #define CGRA_CTRL_BIT_DONE_CONFIG 0x2
    #define CGRA_CTRL_BIT_DONE_EXEC   0x1


#define CGRA_CONF_ADDR_A	0x04
#define CGRA_CONF_SIZE_A	0x08

#define CGRA_IN0_ADDR_A	    0x10
#define CGRA_IN0_SIZE_A	    0x14
#define CGRA_IN1_ADDR_A	    0x18
#define CGRA_IN1_SIZE_A	    0x1C
#define CGRA_IN2_ADDR_A	    0x20
#define CGRA_IN2_SIZE_A	    0x24
#define CGRA_IN3_ADDR_A	    0x28
#define CGRA_IN3_SIZE_A	    0x2C

#define CGRA_OUT0_ADDR_A	0x50
#define CGRA_OUT0_SIZE_A	0x54
#define CGRA_OUT1_ADDR_A	0x58
#define CGRA_OUT1_SIZE_A	0x5C
#define CGRA_OUT2_ADDR_A	0x60
#define CGRA_OUT2_SIZE_A	0x64
#define CGRA_OUT3_ADDR_A	0x68
#define CGRA_OUT3_SIZE_A	0x6C

#define CGRA_CNTR_CONF_A     0x90
#define CGRA_CNTR_EXEC_A     0x94
#define CGRA_CNTR_STALL_A    0x98

