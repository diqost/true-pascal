uses GraphABC,ABCObjects;
const
  ScaleX = 80;
  ScaleY = 25;
  Gravity = 1; 
  //for collisions
type
  collision = record
    left,top,right,bottom:boolean;
  end;
  GameObject = class(RectangleABC)
  public
    velocity: integer;
    collideAny:collision;
    const 
      collision_offset = 10;//offset in pixels
    function getColliderRect():GRectangle;virtual;
    begin
      result:=self.Bounds();
      result.Height:=40;
      result.Width:=40;
      result.Offset(5,5);
      //result.X+=5;
     // result.Y+=5;
    end;
    procedure resetCollisions();
    begin
      collideAny.bottom:=false;
      collideAny.top:=false;
      collideAny.left:=false;
      collideAny.right:=false;
    end;
    function collide(g:gameobject):collision;virtual;
    var
      curBounds:GRectangle;
    begin
      curBounds:=g.getColliderRect();
   
      curBounds.Offset(new GraphABC.Point(-collision_offset,0));
      result.left:= self.IntersectRect(curBounds);
      
      
      curBounds.Offset(new GraphABC.Point(collision_offset * 2 + 1,0));
      result.right:= self.IntersectRect(curBounds);
   
      
      curBounds.Offset(new GraphABC.Point(-collision_offset*2, collision_offset));
      result.top:= self.IntersectRect(curBounds);
  
      curBounds.Offset(new GraphABC.Point(0, -2*collision_offset - 5));
      result.bottom := self.IntersectRect(curBounds);
      
      self.collideAny.bottom:=self.collideAny.bottom or result.bottom;
      self.collideAny.top:=self.collideAny.top or result.top;
      self.collideAny.left:=self.collideAny.left or result.left;
      self.collideAny.right:=self.collideAny.right or result.right;
      
    end;
  end;
  Solidable = interface

  end;
  Gravable = interface(Solidable)
    property isGrounded:boolean read write;
    procedure ApplyGravity;
    procedure Landing(on_y:integer);
  end;
  
  Controllable = interface
    procedure SetMovement(vx: integer; jump: boolean);
  end;
var
  solidObjects := new List<GameObject>;
  gravableObjects:= new List<GameObject>;
  
  //Клавиши
  kLeftKey : boolean;
  kRightKey : boolean;
  kSpaceKey : boolean;
type
  
  Hero = class(GameObject, Gravable,Controllable, Solidable)
  private
    grounded:boolean;
  public 
    procedure SetMovement(vx:integer; jump:boolean);
    begin
      self.dx := vx * self.velocity;
      if (jump and self.isGrounded) then self.Jump();
      
    end;
    procedure ApplyGravity();
    begin
     self.dy += Gravity;
    end;
    procedure Landing(y:integer);
    begin
      self.dy:=0;  
      self.MoveTo(self.Position.X, y - self.Height);
   
      self.grounded:= true;
      //print(self.dy,y,self.grounded);
    end;
    procedure Jump();
    begin
      self.dy:=-20;
      self.grounded:=false;
    end;
    constructor Create(x,y:integer);
    begin
       inherited Create(x, y, 50, 50,GColor.Beige);
       self.velocity:=5;
    end;
    property isGrounded: boolean read grounded write grounded;
    
  end;
  
  Ground = class(GameObject, Solidable)
  public
    constructor Create(x,y,w,h:integer);
    begin
      inherited Create(x,y,w,h,GColor.Aqua);
    
    end;
  end;
var h: Hero;
type 
 GameLevel = class
  public 
    const cell_w = 50;
    const  cell_h = 50;
    const scene_filename = 'level0\scene.in';
    const creatures_filename = 'level0\creatures.in';
    Objects : List<GameObject>;
    SolidObjects : List<GameObject>;
    player: Hero; 
    GravableObjects: List<GameObject>;  
    procedure LoadLevel();
    var 
      i,j,x,y:integer;
      currentSymbol: char;
      current_object: GameObject;
      f:Text;
      aType: string;
    begin
      if (not FileExists(scene_filename)) then 
        raise new System.FormatException('NO FILE ' + scene_filename);
      if (not FileExists(creatures_filename)) then 
        raise new System.FormatException('NO FILE ' +creatures_filename);
      //LOAD MAP STATIC OBJECTS (platforms etc)
      assign(f,scene_filename);
      reset(f);
      Objects:=         new List<GameObject>;
      SolidObjects:=    new List<GameObject>;
      GravableObjects:= new List<GameObject>;  
      
      //Для статических объектов (файл level/scene.in)
      x:=0;y:=0;
      while not eof(f) do
      begin
        x:=-1;
        while not eoln(f) do 
        begin
          inc(x);
          read(f,currentSymbol);
          
          if (currentSymbol = ' ') then continue;
          current_object:=self.CreateBySymbol(currentSymbol,x*cell_w, y*cell_h);
          self.Objects.Add(current_object);
           
          if (currentSymbol = '#') then
          begin
            //Ground
            SolidObjects.Add(current_object);
          end;
          //тут другие блоки (статические)
        end;
        inc(y);
        readln(f);
      end;
      
      close(f);
      //players, enemies, living objects 
      assign(f,creatures_filename);
      reset(f);
      
      while not eof(f) do
      begin  
        readln(f,x,y,aType); //read type of creature
        if (aType.Trim().ToUpper() = 'HERO') then 
        begin
          self.player:= new Hero(x*cell_w,y*cell_h);
          self.GravableObjects.Add(player);
          self.Objects.Add(self.player);
          self.SolidObjects.Add(player);
        end;
      end;
      
      Writeln('TOTAL:', self.GravableObjects.Count, ' grvable');
      
      Writeln('TOTAL:', self.SolidObjects.Count, ' SolidObjects');
      
    end;
    function CreateBySymbol(c: char; x,y:integer):GameObject;
    var 
      g:GameObject;
    begin 
      case c of
       '#': g := new Ground(x,y,cell_w,cell_h);
       else raise new System.FormatException(c);
      end;
      result:=g;
    end;
  end;
 
var
  floor: Ground;
  level: GameLevel;
 

procedure ApplyGravity();
var
  tmp: Gravable;
begin
  foreach var elem in level.GravableObjects do
  begin
    var gr:Gravable:=(elem as Gravable);
    if not gr.isGrounded then begin
      gr.ApplyGravity();
    end;
  end;
end;

procedure CheckCollisions();
var any_floor:boolean;
    res:collision;
begin
  foreach var tested in level.GravableObjects do
  begin
    any_floor:=false;
    foreach var elem in level.SolidObjects do
    begin
       if (tested = elem) then continue;
       res:=tested.collide(elem);
       if res.right then
       begin
         println('colliding right');
        // tested.
         //tested.Position.X:=elem.Position.X +elem.Width + 10;
        // tested.MoveOn(tested.velocity, 0);
         tested.MoveTo(elem.Position.X + elem.Width + 2, tested.Position.Y);
         tested.dx:=0;
       end else if res.left then begin
          println('colliding left');
          tested.MoveTo(elem.Position.X - tested.Width - 2, tested.Position.Y);
          tested.dx:=0;
       end else if res.bottom then
       begin
         writeln('landing');
        if (tested.dy >0 )then
         (tested as Gravable).Landing(elem.Position.Y);
        any_floor:=true;
       end;;
      
 
    end;
    
    if not any_floor then (tested as Gravable).isGrounded:=false;
    
  end;
 
end;


/// Обработчик нажатия клавиши
procedure KeyDown(Key: integer);
begin
  case Key of
vk_Left:  kLeftKey := True;
vk_Right: kRightKey := True;
vk_Space: kSpaceKey := True;
  end;
end;

/// Обработчик отжатия клавиши
procedure KeyUp(Key: integer);
begin
  case Key of
vk_Left:  kLeftKey := False;
vk_Right: kRightKey := False;
vk_Space: kSpaceKey := False;
  end;
end;

procedure CheckControls();
var moveX:integer;

begin
  moveX:=0;
  if (kLeftKey) then dec(moveX);
  if (kRightKey) then inc(moveX);
    level.player.SetMovement(moveX,kSpaceKey);
end;

procedure UpdateCamera();
begin
  SetCoordinateOrigin(0 - level.player.Position.X div 2, - level.player.Position.Y div 2);
  //Coordinate.
end;

var tmp1,tmp2 :integer;
  t,leftT: GameObject;
  rect:GRectangle;
begin
  SetConsoleIO;
  level:=new GameLevel();
  level.LoadLevel();
    GraphABC.DrawInBuffer:=true;
  //Настройка координат
 // level.player.grounded:=false;
  
  //Обрабочики клавиш
  OnKeyDown := KeyDown;
  OnKeyUp := KeyUp;
  SetSmoothing(False);
  ClearWindow();
  t:=new GameObject(0,0,40,40,Gcolor.Red);
  leftT:=new GameObject(0,0,40,40,Gcolor.Green);
  while True do
  begin
    LockDrawingObjects;
    UpdateCamera();
   // ClearWindow();
    CheckControls();
    CheckCollisions();
    ApplyGravity();
    
    for i:integer:= 0 to level.Objects.Count - 1 do
    begin
      level.Objects[i].Move();
    end;
   
    RedrawObjects;
    //Rectangle(,level.player.getColliderRect().Y,level.player.getColliderRect().Width,level.player.getColliderRect().Height);
    //Rectangle();
    sleep(100);
  
   // writeln(level.player.grounded);
  end;
  
end.