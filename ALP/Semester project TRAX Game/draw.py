import os
from PIL import Image
from PIL import ImageColor
from PIL import ImageDraw
from PIL import ImageFont

class Drawer:
    def __init__(self):
        self.res = 100
        self.colors = ["#a2faa3","#92c9b1","#4f759b","#5d5179","#571f4e","#960200","#ce6c47","#ffd046","#f3d8c7","#69385c"]
        self.colors = ["#7798ab","#c3dbc5","#e8dcb9","#f2cee6","#ffa69e","#ff686b","#bf98a0","#6b0504","#a3320b","#9B287B"]

        self.dirname = os.path.dirname(__file__)

        ima = Image.open(self.dirname + "/tiles/tileA100.png")
        imb = Image.open(self.dirname + "/tiles/tileB100.png")
        imawh = Image.open(self.dirname + "/tiles/tileA100wh.png")
        imarh = Image.open(self.dirname + "/tiles/tileA100rh.png")
        imbwh = Image.open(self.dirname + "/tiles/tileB100wh.png")
        imbrh = Image.open(self.dirname + "/tiles/tileB100rh.png")

        self.imgs = {}
        self.imgs["lldd"] = imb;
        self.imgs["dlld"] = imb.copy().rotate(-90)
        self.imgs["ddll"] = imb.copy().rotate(-180)
        self.imgs["lddl"] = imb.copy().rotate(-270)
        self.imgs["ldld"] = ima.copy().rotate(-90);
        self.imgs["dldl"] = ima;
        
        self.imgswh = {}
        self.imgswh["lldd"] = imbwh;
        self.imgswh["dlld"] = imbwh.copy().rotate(-90)
        self.imgswh["ddll"] = imbwh.copy().rotate(-180)
        self.imgswh["lddl"] = imbwh.copy().rotate(-270)
        self.imgswh["ldld"] = imawh.copy().rotate(-90);
        self.imgswh["dldl"] = imawh;

        self.imgsrh = {}
        self.imgsrh["lldd"] = imbrh;
        self.imgsrh["dlld"] = imbrh.copy().rotate(-90)
        self.imgsrh["ddll"] = imbrh.copy().rotate(-180)
        self.imgsrh["lddl"] = imbrh.copy().rotate(-270)
        self.imgsrh["ldld"] = imarh.copy().rotate(-90);
        self.imgsrh["dldl"] = imarh;




    def draw(self, board, filename, lpath = [], dpath = [] ):
        imwidth = len(board[0])*self.res
        imheight = len(board)*self.res
        img = Image.new('RGB', (imwidth,imheight), "white")

        pix = img.load()
        draw = ImageDraw.Draw(img)
                   
        for r in range(len(board)):
            for c in range(len(board[0])):
                if board[r][c] in self.imgs:
                    img.paste(self.imgs[board[r][c]], (self.res*c, self.res*r))
        for p in lpath:
            row,col = p
            if board[row][col] in self.imgswh:
                img.paste(self.imgswh[board[row][col]], (self.res*col, self.res*row))

        for p in dpath:
            row,col = p
            if board[row][col] in self.imgsrh:
                img.paste(self.imgsrh[board[row][col]], (self.res*col, self.res*row))

        for r in range(len(board)):
            draw.line([(0,r*self.res),(imwidth, r*self.res)], fill="red", width=1)
            
        for c in range(len(board[0])):
            draw.line([(c*self.res, 0), (c*self.res, imheight)], fill="red", width=1)

        img.save(self.dirname + "/moves/" + filename)    
