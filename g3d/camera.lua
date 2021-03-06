-- written by groverbuger for g3d
-- august 2020
-- MIT license

function InitializeCamera()
    ----------------------------------------------------------------------------------------------------
    -- initialize the 3d shader
    ----------------------------------------------------------------------------------------------------

    CameraShader = love.graphics.newShader [[
        uniform mat4 projectionMatrix;
        uniform mat4 modelMatrix;
        uniform mat4 viewMatrix;

        #ifdef VERTEX
            vec4 position(mat4 transform_projection, vec4 vertex_position)
            {
                return projectionMatrix * viewMatrix * modelMatrix * vertex_position;
            }
        #endif

        #ifdef PIXEL
            vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
            {
                vec4 texcolor = Texel(tex, texcoord);
                if (texcolor.a == 0.0) { discard; }
                return vec4(texcolor);
            }
        #endif
    ]]

    ----------------------------------------------------------------------------------------------------
    -- initialize the shader with a basic camera
    ----------------------------------------------------------------------------------------------------

    Camera = {
        fov = math.pi/2,
        nearClip = 0.01,
        farClip = 1000,
        aspectRatio = love.graphics.getWidth()/love.graphics.getHeight(),

        position = {0,0,0},
        direction = 0,
        pitch = 0,
        down = {0,-1,0},
    }

    -- create the projection matrix from the camera
    -- and send it to the shader
    CameraShader:send("projectionMatrix", GetProjectionMatrix(Camera.fov, Camera.nearClip, Camera.farClip, Camera.aspectRatio))
    
    SetCamera(0,0,0,0,0)

    -- so that far polygons don't overlap near polygons
    love.graphics.setDepthMode("lequal", true)
end

-- move and rotate the camera, given a point and a direction and a pitch (vertical direction)
function SetCamera(x,y,z, direction,pitch)
    Camera.position = {x,y,z}
    Camera.direction = direction or Camera.direction
    Camera.pitch = pitch or Camera.pitch

    -- convert the direction and pitch into a target point
    local sign = math.cos(Camera.pitch)
    if sign > 0 then
        sign = 1
    elseif sign < 0 then
        sign = -1
    else
        sign = 0
    end
    local cosPitch = sign*math.max(math.abs(math.cos(Camera.pitch)), 0.001)
    local target = {Camera.position[1]+math.sin(Camera.direction)*cosPitch, Camera.position[2]-math.sin(Camera.pitch), Camera.position[3]+math.cos(Camera.direction)*cosPitch}
    Camera.target = target

    -- update the camera in the shader
    CameraShader:send("viewMatrix", GetViewMatrix(Camera.position, Camera.target, Camera.down))
end

-- give the camera a point to look from and a point to look towards
function SetCameraAndLookAt(x,y,z, xAt,yAt,zAt)
    Camera.position = {x,y,z}
    Camera.target = {xAt,yAt,zAt}

    -- update the camera in the shader
    CameraShader:send("viewMatrix", GetViewMatrix(Camera.position, Camera.target, Camera.down))
end

-- simple first person camera movement with WASD
-- put this function in your love.update to use, passing in dt
function FirstPersonCameraMovement(dt)
    -- collect inputs
    local mx,my = 0,0
    local cameraMoved = false
    if love.keyboard.isDown("w") then
        my = my - 1
    end
    if love.keyboard.isDown("a") then
        mx = mx - 1
    end
    if love.keyboard.isDown("s") then
        my = my + 1
    end
    if love.keyboard.isDown("d") then
        mx = mx + 1
    end
    if love.keyboard.isDown("space") then
        Camera.position[2] = Camera.position[2] - 0.15*dt*60
        cameraMoved = true
    end
    if love.keyboard.isDown("lshift") then
        Camera.position[2] = Camera.position[2] + 0.15*dt*60
        cameraMoved = true
    end

    -- add camera's direction and movement direction
    -- then move in the resulting direction
    if mx ~= 0 or my ~= 0 then
        local angle = math.atan2(my,mx)
        local speed = 0.15
        local dx,dz = math.cos(Camera.direction + angle)*speed*dt*60, math.sin(Camera.direction + angle + math.pi)*speed*dt*60

        Camera.position[1] = Camera.position[1] + dx
        Camera.position[3] = Camera.position[3] + dz
        cameraMoved = true
    end

    if cameraMoved then
        SetCamera(Camera.position[1],Camera.position[2],Camera.position[3], Camera.direction,Camera.pitch)
    end
end

-- best served with FirstPersonCameraMovement()
-- use this in your love.mousemoved function, passing in the movements
function FirstPersonCameraLook(dx,dy)
    love.mouse.setRelativeMode(true)
    local sensitivity = 1/300
    Camera.direction = Camera.direction + dx*sensitivity
    Camera.pitch = math.max(math.min(Camera.pitch - dy*sensitivity, math.pi*0.5), math.pi*-0.5)

    SetCamera(Camera.position[1],Camera.position[2],Camera.position[3], Camera.direction,Camera.pitch)
end
