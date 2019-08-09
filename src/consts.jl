# Constants - from mathlink.h

@enum Packet begin
  PKT_ILLEGAL    =   0

  PKT_CALL       =   7
  PKT_EVALUATE   =  13
  PKT_RETURN     =   3

  PKT_INPUTNAME  =   8
  PKT_ENTERTEXT  =  14
  PKT_ENTEREXPR  =  15
  PKT_OUTPUTNAME =   9
  PKT_RETURNTEXT =   4
  PKT_RETURNEXPR =  16

  PKT_DISPLAY    =  11
  PKT_DISPLAYEND =  12

  PKT_MESSAGE    =   5
  PKT_TEXT       =   2

  PKT_INPUT      =   1
  PKT_INPUTSTR   =  21
  PKT_MENU       =   6
  PKT_SYNTAX     =  10

  PKT_SUSPEND    =  17
  PKT_RESUME     =  18

  PKT_BEGINDLG   =  19
  PKT_ENDDLG     =  20

  PKT_FIRSTUSER  = 128
  PKT_LASTUSER   = 255
end

@enum Token begin
    TK_ERROR    = 0           # /* bad token */

    TK_OLDINT   = Cint('I')   # /* 73 Ox49 01001001 */ # /* integer leaf node */
    TK_OLDREAL  = Cint('R')   # /* 82 Ox52 01010010 */ # /* real leaf node */
    TK_FUNC     = Cint('F')   # /* 70 Ox46 01000110 */ # /* non-leaf node */

    TK_STR      = Cint('"')   # /* 34 0x22 00100010 */
    TK_SYM      = Cint('#')   # /* 35 0x23 # 00100011 */

    TK_REAL     = Cint('*')   # /* 42 0x2A 00101010 */
    TK_INT      = Cint('+')   # /* 43 0x2B 00101011 */

    # /* The following defines are for internal use only */
    TK_PCTEND   = Cint(']')    # /* at end of top level expression */
    TK_END      = Cint('\n')
    TK_AEND     = Cint('\r')
    TK_SEND     = Cint(',')
    TK_CONT     = Cint('\\')
    TK_ELEN     = Cint(')')
    TK_NULL     = Cint('.')
    TK_OLDSYM   = Cint('Y')    # /* 89 0x59 01011001 */
    TK_OLDSTR   = Cint('S')    # /* 83 0x53 01010011 */    
    TK_PACKED   = Cint('P')    # /* 80 0x50 01010000 */
    TK_ARRAY    = Cint('A')    # /* 65 0x41 01000001 */
    TK_DIM      = Cint('D')    # /* 68 0x44 01000100 */
    
    TK_INVALID  = 155
    TK_INT8     = 160
    TK_UINT8    = 161
    
    TK_INT16_BE    = 162
    TK_UINT16_BE   = 163
    TK_INT32_BE    = 164
    TK_UINT32_BE   = 165
    TK_INT64_BE    = 166
    TK_UINT64_BE   = 167

    TK_INT16_LE    = 226
    TK_UINT16_LE   = 227
    TK_INT32_LE    = 228
    TK_UINT32_LE   = 229
    TK_INT64_LE    = 230
    TK_UINT64_LE   = 231
    
    TK_FLOAT32_BE  = 180
    TK_FLOAT64_BE  = 182
    TK_FLOAT128_BE = 184

    TK_FLOAT32_LE  = 244
    TK_FLOAT64_LE  = 246
    TK_FLOAT128_LE = 248
    
end

module ERR
  const UNKNOWN         =   -1
  const OK              =    0
  const DEAD            =    1
  const GBAD            =    2
  const GSEQ            =    3
  const PBTK            =    4
  const PSEQ            =    5
  const PBIG            =    6
  const OVFL            =    7
  const MEM             =    8
  const ACCEPT          =    9
  const CONNECT         =   10
  const CLOSED          =   11
  const DEPTH           =   12  # /* internal error */
  const NODUPFCN        =   13  # /* stream cannot be duplicated */

  const NOACK           =   15  # /* */
  const NODATA          =   16  # /* */
  const NOTDELIVERED    =   17  # /* */
  const NOMSG           =   18  # /* */
  const FAILED          =   19  # /* */

  const GETENDEXPR      =   20
  const PUTENDPACKET    =   21 # /* unexpected call of MLEndPacket */
                               # /* currently atoms aren't
                               # * counted on the way out so this error is raised only when
                               # * MLEndPacket is called in the midst of an atom
                               # */
  const NEXTPACKET      =   22
  const UNKNOWNPACKET   =   23
  const GETENDPACKET    =   24
  const ABORT           =   25
  const MORE            =   26 # /* internal error */
  const NEWLIB          =   27
  const OLDLIB          =   28
  const BADPARAM        =   29
  const NOTIMPLEMENTED  =   30


  const INIT            =   32
  const ARGV            =   33
  const PROTOCOL        =   34
  const MODE            =   35
  const LAUNCH          =   36
  const LAUNCHAGAIN     =   37
  const LAUNCHSPACE     =   38
  const NOPARENT        =   39
  const NAMETAKEN       =   40
  const NOLISTEN        =   41
  const BADNAME         =   42
  const BADHOST         =   43
  const RESOURCE        =   44  # /* a required resource was missing */
  const LAUNCHFAILED    =   45
  const LAUNCHNAME      =   46

  const PDATABAD        =   47
  const PSCONVERT       =   48
  const GSCONVERT       =   49
  const NOTEXE          =   50
  const SYNCOBJECTMAKE  =   51
  const BACKOUT         =   52

  const TRACEON         =  996  # /* */
  const TRACEOFF        =  997  # /* */
  const DEBUG           =  998  # /* */
  const ASSERT          =  999  # /* an internal assertion failed */
  const USER            = 1000  # /* start of user defined errors */
end
