//==============================================================
// FULL ADDER
//==============================================================
module full_adder(input a,b,cin, output sum,cout);
    assign sum  = a ^ b ^ cin;
    assign cout = (a&b) | (a&cin) | (b&cin);
endmodule



//==============================================================
// 8 BIT ADDER
//==============================================================
module adder8(input [7:0] A,B, output [7:0] S, output Cout);

    wire c1,c2,c3,c4,c5,c6,c7;

    full_adder f0(A[0],B[0],1'b0,S[0],c1);
    full_adder f1(A[1],B[1],c1,S[1],c2);
    full_adder f2(A[2],B[2],c2,S[2],c3);
    full_adder f3(A[3],B[3],c3,S[3],c4);
    full_adder f4(A[4],B[4],c4,S[4],c5);
    full_adder f5(A[5],B[5],c5,S[5],c6);
    full_adder f6(A[6],B[6],c6,S[6],c7);
    full_adder f7(A[7],B[7],c7,S[7],Cout);

endmodule



//==============================================================
// SUBTRACTOR
//==============================================================
module sub8(input [7:0] A,B, output [7:0] D);

    wire [7:0] B2;
    wire c;

    assign B2 = ~B + 1'b1;
    adder8 U1(A,B2,D,c);

endmodule



//==============================================================
// BOOTH RADIX-4
//==============================================================
module booth_radix4(
    input signed [7:0] M,
    input signed [7:0] Q,
    output reg signed [15:0] P
);

    integer i;
    reg signed [15:0] temp;
    reg [2:0] bits;

    always @(*) begin

        temp = 0;

        for(i=0;i<4;i=i+1)
        begin

        case(i)
            0: bits = {Q[1],Q[0],1'b0};
            1: bits = {Q[3],Q[2],Q[1]};
            2: bits = {Q[5],Q[4],Q[3]};
            3: bits = {Q[7],Q[6],Q[5]};
        endcase

        case(bits)
            3'b000,3'b111: temp=temp;
            3'b001,3'b010: temp=temp + (M <<< (2*i));
            3'b011:        temp=temp + (M <<< (2*i+1));
            3'b100:        temp=temp - (M <<< (2*i+1));
            3'b101,3'b110: temp=temp - (M <<< (2*i));
        endcase

        end

        P=temp;

        end
endmodule



//==============================================================
// SRT RADIX-2 DIVISION
//==============================================================
module srt2_div(
    input [7:0] Dividend,
    input [7:0] Divisor,
    output reg [7:0] Quotient,
    output reg [7:0] Remainder
);

    integer i;
    reg [8:0] temp;

    always @(*) begin

    Quotient  = 0;
    Remainder = 0;
    temp = 0;

    if(Divisor==0)
    begin
        Quotient  = 8'hFF;
        Remainder = 8'hFF;
    end
    else begin

        for(i=7;i>=0;i=i-1)
        begin

            temp = {Remainder[7:0], Dividend[i]};

            if(temp >= Divisor)
            begin
                temp = temp - Divisor;
                Quotient[i] = 1'b1;
            end
            else
                Quotient[i] = 1'b0;

                Remainder = temp[7:0];

            end

      end
  end
endmodule



module alu_top(
    input [7:0] A,
    input [7:0] B,
    input [1:0] opcode,

    output reg [15:0] RESULT,
    output reg [7:0] REMAINDER
);

    wire [7:0] add_raw;
    wire [7:0] sub_raw;
    wire [15:0] mul_raw;
    wire [7:0] q_raw;
    wire [7:0] r_raw;

    wire c;


    adder8       U1(A,B,add_raw,c);
    sub8         U2(A,B,sub_raw);
    booth_radix4 U3(A,B,mul_raw);
    srt2_div     U4(A,B,q_raw,r_raw);



    always @(*) begin
      
        RESULT    = 16'b0;
        REMAINDER = 8'b0;

    case(opcode)

    // ADD
    2'b00: begin
        RESULT = {8'b0, add_raw};
    end

    // SUB
    2'b01: begin
        RESULT = {8'b0, sub_raw};
    end

    // MUL
    2'b10: begin
        RESULT = mul_raw;
    end

    // DIV
    2'b11: begin
        RESULT    = {8'b0, q_raw};  
        REMAINDER = r_raw;          
    end

    endcase

end

endmodule

module tb_alu;

    reg [7:0] A,B;
    reg [1:0] opcode;

    wire [15:0] RESULT;
    wire [7:0] REMAINDER;

    alu_top DUT(
      A,B,opcode,
      RESULT,
      REMAINDER
    );

    initial begin

      $display("===== ALU CLEAN TEST =====");

      // ADD
      //A=10; B=5; opcode=2'b00; #10;

      // SUB
      //A=20; B=7; opcode=2'b01; #10;

      // MUL
      //A=6; B=4; opcode=2'b10; #10;

      // DIV
      A=20; B=3; opcode=2'b11; #10;

      // DIV
      //A=45; B=6; opcode=2'b11; #10;

      $stop;

    end

endmodule

